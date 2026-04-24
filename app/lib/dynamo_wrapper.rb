class DynamoWrapper
  include TimingEvents

  attr_reader :profile, :region
  attr_accessor :table

  delegate :errors, to: :latency_logger
  delegate :error_messages, to: :latency_logger
  delegate :errors?, to: :latency_logger

  def initialize(table:, profile: nil, region: nil, loggers: [])
    @region = region || DynamoConfig.region
    @profile = profile
    @loggers = loggers
    self.table = table
  end

  # This method queries the dynamoDB for an object with the specified {primary_key}.
  # If the object is found, it will return an object where the keys are the ones defined
  # in the {selected_attributes} array.
  #
  # @params {primary_key} Required - array of hashes representing the PK of the dynamoDB
  #   object to find.
  # @params {selected_attributes} Required - Array of strings representing the expected
  #   columns to be seen in the selected object.

  def find(primary_key:, selected_attributes:)
    request = {
      request_items: {
        table => {
          keys: primary_key,
          attributes_to_get: selected_attributes
        }
      }
    }
    latency_logger.with_query_logging(
      metric: :find_query,
      info: { primary_key: primary_key }
    ) do
      result = client.batch_get_item(request)
      result.responses[table]
    end
  end

  # This method inserts the {keypair_item} in the dynamoDB table
  # as a new object. If there is an existing object in dynamoDB with
  # the same primary key, this method will OVERRIDE the existing one
  # replacing ALL the object with {keypair_item}.
  #
  # @params {new_item} Required - hash representing the dynamo object.

  def put(new_item:)
    latency_logger.with_query_logging(
      metric: :put_query,
      info: { item: new_item }
    ) do
      client.put_item(item: new_item, table_name: table)
    end
  end

  # This method will edit an existing dynamoDB object with the {keypair_updates}.
  # If an attribute does not exist in the current dynamoDB object, this method will add it to
  # the existing dynamoDB object.
  # If there is no dynamoDB objects with the specified {primary_key}, it will create
  # a new one using {keypair_updates}.
  #
  # @params {primary_key} Required - array of hashes representing the PK of the
  #   dynamoDB object to update.
  # @params {item_updates} Required - hash containing the attributes to be updated
  #   with the new values.

  def update(primary_key:, item_updates:)
    # In order to safely update an object in dynamo, we need to prepend '#' to every key
    # specified and create value placeholders using the ':' symbol.
    # TODO: Implement a way to detect and parse nested key attributes? (eg: user_1.video)

    attribute_names = {}
    value_placeholders = {}
    update_statements = []
    item_updates.each do |name, value|
      # the attribute_names object should be { #key_1 => key_1, ... }
      attribute_names["##{name}"] = name
      # the value_placeholders object should be { :key_1 => value_1, ... }
      value_placeholders[":#{name}"] = value
      # ["#key_1 = :key_1", "#key_2 = :key_2", ...]
      update_statements << "##{name} = :#{name}"
    end

    # This will create the UPDATE query using the value placeholders and attribute names.
    # update_query should be #key_1 = :key_1, #key_2 = :key_2, ...
    update_query = update_statements.join(', ')

    update_item(key: primary_key,
                table_name: table,
                expression_attribute_names: attribute_names,
                expression_attribute_values: value_placeholders,
                update_expression: "SET #{update_query}")
  end

  def update_item(args)
    latency_logger.with_query_logging(
      metric: :update_query,
      info: { primary_key: args[:key] }
    ) do
      client.update_item(args)
    end
  end

  def delete_item(primary_key:)
    latency_logger.with_query_logging(
      metric: :delete_query,
      info: { primary_key: primary_key }
    ) do
      client.delete_item(
        key: primary_key,
        table_name: table)
    end
  end

  def client
    @client ||= Aws::DynamoDB::Client.new(
      { region: region }.tap { |memo| memo[:credentials] = aws_credentials if profile }
    )
  end

  private def aws_credentials
    @aws_credentials ||= Aws::SharedCredentials.new(profile_name: profile)
  end

  private def latency_logger
    @latency_logger ||= LatencyLogger.new(@loggers)
  end

  class LatencyLogger
    include TimingEvents

    attr_reader :errors

    def initialize(loggers)
      @loggers = loggers
      @errors = []
    end

    def errors?
      @errors.any?
    end

    def error_messages
      @errors.map(&:message)
    end

    def with_query_logging(metric:, info:)
      # Clear errors first
      @errors = []
      result = time_event(metric) do
        yield
      end
      log(metric: metric, info: info)
      result
    rescue StandardError => e
      VHLMonitor.notify(e)
      log(metric: metric, info: info, error: e)
      @errors << e
    end

    def log(metric:, info:, error: nil)
      return if @loggers.empty?

      latency = response_time[metric].to_i
      @loggers.each do |logger|
        logger.log(latency: latency, metric: metric, info: info, error: error)
      end
    end
  end

  class LogStashLogger
    include StatsProcessor

    SERVICE = 'dynamodb'.freeze

    def initialize(stats_index:, dynamo_table:)
      @stats_index = stats_index
      @dynamo_table = dynamo_table
    end

    def log(latency:, metric:, info:, error: nil)
      data = {
        dynamo_table: @dynamo_table,
        service: SERVICE,
        latency: { duration: latency },
        additional_info: info
      }
      dispatch(payload: data,
               stats_index: @stats_index,
               stats_type: "#{metric}_latency",
               error: error)
    end
  end

  class DatadogLogger
    include DatadogProcessor

    ROLE = 'dynamo'.freeze

    def log(latency:, metric:, **attrs)
      ddog_dispatch(metric: "m3.dynamo.#{metric}.latency",
                    stats_type: :gauge,
                    role: ROLE,
                    value: latency)
    end
  end
end
