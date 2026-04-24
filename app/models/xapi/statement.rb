require 'xapi'
require 'hashie'

module Xapi
  class Statement
    include VhlAwsRecord

    OBJECT_TYPE_ACTIVITY = 'Activity'.freeze
    STATEMENT_COMPARISON_IGNORED_ATTRS = %i[id timestamp stored].freeze
    UNIQUENESS_STATEMENT_SORT_KEY = 'uniqueness_statement_sort_key'.freeze
    VERB_SHORT_FORM_LOOKUP = {
      VERB_ATTEMPTED => 'attempted',
      VERB_ANSWERED => 'answered',
      VERB_INITIALIZED => 'initialized',
      VERB_EXPERIENCED => 'experienced',
      VERB_TERMINATED => 'terminated'
    }.freeze

    set_table_name(prefix_table_name('xapi-statements'))

    string_attr :pk, hash_key: true
    string_attr :sk, range_key: true
    string_attr :attempt_id
    string_attr :id
    time_attr :stored
    # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#24-statement-properties
    # Set by the LRS if not provided.
    time_attr :timestamp
    string_attr :verb
    string_attr :serialized_attrs

    delegate :object, :result, to: :attrs
    delegate :score, to: :result
    delegate :interaction, to: :object, allow_nil: true

    def initialize(attr_values = {})
      super()
      self.serialized_attrs = attr_values.to_json
      # Only set denormalized values if the statement is created with attribute
      # values. This is to prevent the `attr` memoization before having a fully
      # initialized object.
      set_denormalized_values unless attr_values.empty?
    end

    private def set_denormalized_values
      self.id = attrs[:id]
      self.timestamp = Time.parse(attrs[:timestamp])
      self.stored = attrs.key?(:stored) ? Time.parse(attrs[:stored]) : timestamp
      self.verb = attrs[:verb]
    end

    def attrs
      @attrs ||= NoWarningHashieMash.new(
        serialized_attrs ? JSON.parse(serialized_attrs, symbolize_names: true) : {}
      )
    end

    def self.query_by_pk(key, **extra_args)
      query(
        {
          key_condition_expression: '#pk_name = :pk_value',
          expression_attribute_names: { '#pk_name' => 'pk' },
          expression_attribute_values: { ':pk_value' => key.to_s }
        }.merge(extra_args)
      )
    end

    def self.query_by_statement_id(id_value)
      query_by_pk(id_value).first
    end

    def self.query_by_attempt(attempt, **extra_args)
      query_by_pk(attempt.id, **extra_args)
    end

    def self.query_for_answered(attempt)
      query(
        key_condition_expression: '#pk_name = :pk_value and begins_with(#sk,:sk_value)',
        expression_attribute_names: {
          '#pk_name' => 'pk', '#sk' => 'sk'
        },
        expression_attribute_values: {
          ':pk_value' => attempt.id.to_s,
          ':sk_value' => VERB_SHORT_FORM_LOOKUP[VERB_ANSWERED]
        }
      )
    end

    def self.query_for_answered_count(attempt, **extra_args)
      # We only want to know the number of statements with the verb "answered".
      # We aren't interested in the satements themself.
      # From the documentation: "When using `select: 'COUNT"'`, the query returns
      # the number of matching items, rather than the matching items themselves.
      # https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Query.html#DDB-Query-request-Select
      #
      # Also to be sure to count all the statements, we sum the number of item
      # per page.
      # From the documentation: "If LastEvaluatedKey is not empty, it does not
      # necessarily mean that there is more data in the result set. The only
      # way to know when you ave reached the end of the result set is when
      # LastEvaluatedKey is empty."
      # https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Query.html#DDB-Query-response-LastEvaluatedKey
      args = {
        table_name: table_name,
        key_condition_expression: '#pk_name = :pk_value and begins_with(#sk,:sk_value)',
        expression_attribute_names: {
          '#pk_name' => 'pk', '#sk' => 'sk'
        },
        expression_attribute_values: {
          ':pk_value' => attempt.id.to_s,
          ':sk_value' => VERB_SHORT_FORM_LOOKUP[VERB_ANSWERED]
        },
        select: 'COUNT'
      }.merge(extra_args)
      count = 0
      dynamodb_client.query(args).each_page do |page|
        count += page.count
      end
      count
    end

    def self.query_for_duration(attempt)
      query(
        key_condition_expression: '#pk_name = :pk_value',
        expression_attribute_names: {
          '#pk_name' => 'pk',
          '#timestamp' => 'timestamp'
        },
        expression_attribute_values: { ':pk_value' => attempt.id.to_s },
        projection_expression: 'verb, #timestamp'
      )
    end

    # Delete all the statements related to the attempt.
    # This method only deletes the statements that have the statement sort key.
    # It does not delete statements used to check for uniqueness.
    # This method uses the `batch_write_item` method to delete up to 25 items
    # at a time:
    # https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchWriteItem.html
    def self.delete_statements_by_attempt(attempt)
      # We query all the statements for that attempt but we are only interested
      # in the pk and sk attributes.
      all_statements = query_by_attempt(attempt, projection_expression: 'pk, sk')
      all_statements.each_slice(25) do |statements|
        dynamodb_client.batch_write_item(
          request_items: {
            table_name => statements.map do |statement|
              {
                delete_request: { key: { pk: statement.pk, sk: statement.sk } }
              }
            end
          }
        )
      end
    end

    # Add a new statement to the LRS.
    # Check for conflicts if storage fails. Upon conflict retrieve the stored version
    # and check if the incoming one is different. If so record a warning.
    # In all cases where the incoming statement can't be stored, return unsuccessful to
    # signal that this statement does not require further processing.
    # Either we have it or there is a problem with it.
    #
    # NOTES from xAPI spc:
    #   # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#24-statement-properties
    # Note: 'actor', 'verb' and 'object' are required.
    # Currently, we want to assume that the learning maker activities are going
    # to correctly conform to the standard, then it's enough for us to just store
    # whatever we get without validations.
    def store(attempt)
      self.pk = attempt.id.to_s
      self.sk = statement_sort_key
      self.attempt_id = attempt.id
      save_with_transaction
    end

    private def save_with_transaction
      Aws::Record::Transactions.transact_write(
        client: dynamodb_client,
        transact_items: [
          { save: self },
          { save: uniqueness_statement }
        ]
      )
      true
    rescue Aws::DynamoDB::Errors::TransactionCanceledException
      existing_statement = self.class.query_by_statement_id(id)
      if existing_statement && conflict_with?(existing_statement)
        VHLMonitor.warning("LRS statement conflict for statement id: #{id}")
      end
      false
    end

    # build a duplicate that uses the statement id as the partition key;
    # that will then cause a subsequent duplicate with the same statement id
    # to fail to save.
    private def uniqueness_statement
      # Don't memoize because attempt_id and id could change between calls.
      self.class.new(attrs).tap do |statement|
        statement.attempt_id = attempt_id
        statement.pk = id.to_s
        statement.sk = UNIQUENESS_STATEMENT_SORT_KEY
      end
    end

    def <=>(other)
      timestamp <=> other.timestamp
    end

    def ==(other)
      id == other.id &&
        stored == other.stored &&
        timestamp == other.timestamp &&
        attrs == other.attrs
    end

    def conflict_with?(other_statement)
      # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#statement-comparision-requirements
      attrs.except(*STATEMENT_COMPARISON_IGNORED_ATTRS) !=
        other_statement.attrs.except(*STATEMENT_COMPARISON_IGNORED_ATTRS)
    end

    def has_score?
      @has_score ||= verb == VERB_ANSWERED && score
    end

    def gradable?
      has_score? || response_to_instructor_graded_interaction?
    end

    def answered?
      verb == VERB_ANSWERED
    end

    def activity_id
      @activity_id ||= object[:id]
    end

    def response_to_instructor_graded_interaction?
      ::Smartbook::Response.new(attrs).instructor_gradable?
    end

    def object_type
      # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#details-8
      # Objects which are provided as a value for this property SHOULD include an
      # "objectType" property. If not specified, the objectType is assumed to be Activity
      @object_type ||= (object[:objectType] || OBJECT_TYPE_ACTIVITY)
    end

    def page_location
      # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#2441-when-the-objecttype-is-activity
      object[:id] if object_type == OBJECT_TYPE_ACTIVITY
      # We don't always have a 'page location'. For example when the object_type is 'StatementRef'
      # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#2443-when-the-object-is-a-statement
    end

    private def statement_sort_key
      "#{VERB_SHORT_FORM_LOOKUP[verb]}:#{id}"
    end

    # The attribute `score` contains the keys `min` and `max`. When creating
    # a hashie mash object, a reader and writer methods for `min` and `max`
    # are automatically created and they conflict with the build-in methods
    # defined in Enumerable.
    # It's not a problem because we always access the `min` and `max` keys via
    # the #[] method. But hashie still logs a message for every statement. So
    # we subclass the Hashie::Mash class and disable the warning in the subclass.
    class NoWarningHashieMash < Hashie::Mash
      disable_warnings
    end
  end
end
