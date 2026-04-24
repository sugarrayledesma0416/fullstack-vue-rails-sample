module Cartridge
  class Consumer < ApplicationRecord
    include Dangerfield::Subscriber

    # This table is required in M3 in order to sign the grade pass back request.
    self.table_name = 'cartridge_consumers'

    belongs_to :school

    subscribe to: self
    dangerfield_before_update :assign_related_objects
    dangerfield_exclude_on_update %w[id school_guid]
    dangerfield_reject_if :missing_school?

    def assign_related_objects(received_attrs)
      return true unless new_record?

      self.school = find_school(received_attrs)
    end

    private def missing_school?(received_attrs)
      (received_attrs['school_guid'].nil? ||
       find_school(received_attrs).nil?).tap do |missing|
        Rails.logger.debug("missing school - attrs: #{received_attrs}") if missing
      end
    end

    private def find_school(received_attrs)
      School.find_by(guid: received_attrs['school_guid'])
    end
  end
end
