module Lti
  class Launch < ApplicationRecord
    include Dangerfield::Subscriber

    self.table_name = 'lti_launches'

    self.ignored_columns += %w[jwt lti_tool_id state]

    subscribe to: self
    dangerfield_before_update :assign_related_objects
    dangerfield_exclude_on_update %w[id jwt lti_tool_id state lti_platform_guid]
    # a new record should not be added if the related lti_platform record has
    # not been created.
    dangerfield_reject_if :missing_lti_platform?

    # Dangerfield support - adding a new instance via subscription;
    # Before saving need to look up related objects by guid and add them
    # so their ids get stored with the new instance.
    # Because of the way that dangerfield works this method will also be
    # called when an existing object is receiving an update from rostering
    # so check if it has an id before proceeding.
    def assign_related_objects(received_attrs)
      return true unless new_record?

      self.lti_platform_id = find_lti_platform(received_attrs).id
    end

    belongs_to(
      :platform,
      foreign_key: :lti_platform_id,
      class_name: 'Lti::Platform'
    )

    serialize :deep_linking_settings

    # Added for the ability to query dates by >, >=, <, <= without interpolated strings,
    # using `.gt`, `.gteq`, `.lt`, `.lteq`
    def self.created_at_column
      arel_table[:created_at]
    end

    # Convert the attribute into a hash with indifferent access to make our life easier.
    def deep_linking_settings
      convert_to_hash_with_indifferent_access(super)
    end

    def deep_link_data
      deep_linking_settings[:data]
    end

    def deep_link_return_url
      deep_linking_settings[:deep_link_return_url]
    end

    def platform_user_id
      lms_user_id
    end

    private def convert_to_hash_with_indifferent_access(value)
      if value.is_a?(Hash)
        value.with_indifferent_access
      else
        value
      end
    end

    # reject the SNS push if the lti_platform is missing from either the
    # incoming parameters or the M3 database
    private def missing_lti_platform?(received_attrs)
      received_attrs['lti_platform_guid'].nil? || find_lti_platform(received_attrs).nil?
    end

    private def find_lti_platform(received_attrs)
      Lti::Platform.find_by(guid: received_attrs['lti_platform_guid'])
    end
  end
end
