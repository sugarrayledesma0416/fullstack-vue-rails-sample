module Lti
  class Platform < ApplicationRecord
    include Dangerfield::Subscriber
    include Etl

    ROSTERING_TRANSITION_FROM_RA = 'RA'.freeze
    ROSTERING_TRANSITION_FROM_CLEVER = 'Clever'.freeze

    SERVICE_TYPE_SELF_ROSTERING = 'Self-Roster'.freeze
    SERVICE_TYPE_SIMPLE_ROSTERING = 'Simple Roster'.freeze
    SERVICE_TYPE_PREMIUM_ROSTERING = 'Premium Roster'.freeze
    SERVICE_TYPES_WITH_ROSTERING = [
      SERVICE_TYPE_SIMPLE_ROSTERING,
      SERVICE_TYPE_PREMIUM_ROSTERING
    ].freeze

    self.table_name = 'lti_platforms'

    after_commit :update_gradebook

    subscribe to: self

    dangerfield_exclude_on_update %w[clever_filtering locked school_guid]
    dangerfield_before_update :assign_related_objects

    # The platform *must* belong to a school if the platform is configured
    # for rostering or for cartridge.
    # The platform *may* belong to a school if the platform is configured
    # for non-rostering.
    # We do not have custom validations for that. The validations are done by
    # the publisher (UA).
    belongs_to :school, optional: true

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

    def assign_related_objects(received_attrs)
      self.school = School.find_by(guid: received_attrs['school_guid'])
    end

    def rostering_transition_from_ra?
      rostering_transition_from == ROSTERING_TRANSITION_FROM_RA
    end

    def rostering_transition_from_clever?
      rostering_transition_from == ROSTERING_TRANSITION_FROM_CLEVER
    end

    def rostering_simple_service?
      service_type == SERVICE_TYPE_SIMPLE_ROSTERING
    end

    def rostering_premium_service?
      service_type == SERVICE_TYPE_PREMIUM_ROSTERING
    end
  end
end
