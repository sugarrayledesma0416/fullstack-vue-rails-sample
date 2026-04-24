module Lti
  class ContextLink < ApplicationRecord
    include Dangerfield::Subscriber
    include Etl

    self.table_name = 'lti_context_links'

    self.ignored_columns = %w[client_id]

    belongs_to :lti_platform, class_name: 'Lti::Platform'
    belongs_to :section

    after_commit :update_gradebook

    subscribe to: self
    dangerfield_before_update :assign_related_objects
    dangerfield_exclude_on_update %w[id lti_platform_guid section_guid]
    # a new record should not be added if the related lti_platform or section
    # records have not been created.
    dangerfield_reject_if :missing_lti_platform_or_section?

    # Dangerfield support - adding a new instance via subscription;
    # Before saving need to look up related objects by guid and add them
    # so their ids get stored with the new instance.
    # Because of the way that dangerfield works this method will also be
    # called when an existing object is receiving an update from rostering
    # so check if it has an id before proceeding.
    def assign_related_objects(received_attrs)
      return true unless new_record?

      self.lti_platform = find_lti_platform(received_attrs)
      self.section = find_section(received_attrs)
    end

    # Dangerfield::Subscriber uses the `.delete` class method instead of
    # the `#destroy` instance method to skip callbacks, to avoid triggering
    # an infinite loop of executing the dangerfield callbacks. However, this
    # means the updated_gradebook after_commit callback doesn't fire,
    # leaving orphaned gradebook records.
    # Overriding the `.delete` class method method so it calls the gradebook
    # notify_deletion method on each instance ensures the gradebook record gets
    # cleaned up.
    def self.delete(id_or_array)
      where(id: id_or_array).find_each(&:notify_deletion)
      super
    end

    # reject the SNS push if either the lti_platform or the section
    # is missing from either the incoming parameters or the M3 database
    private def missing_lti_platform_or_section?(received_attrs)
      missing_lti_platform?(received_attrs) || missing_section?(received_attrs)
    end

    private def missing_lti_platform?(received_attrs)
      received_attrs['lti_platform_guid'].nil? || find_lti_platform(received_attrs).nil?
    end

    private def missing_section?(received_attrs)
      received_attrs['section_guid'].nil? || find_section(received_attrs).nil?
    end

    private def find_lti_platform(received_attrs)
      Lti::Platform.find_by(guid: received_attrs['lti_platform_guid'])
    end

    private def find_section(received_attrs)
      Section.find_by(guid: received_attrs['section_guid'])
    end
  end
end
