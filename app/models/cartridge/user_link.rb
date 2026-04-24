module Cartridge
  class UserLink < ApplicationRecord
    include Dangerfield::Subscriber

    self.table_name = 'cartridge_user_links'

    belongs_to :school
    belongs_to :user

    subscribe to: self
    dangerfield_before_update :assign_related_objects
    dangerfield_exclude_on_update %w[id school_guid user_guid]
    dangerfield_reject_if :missing_school_or_user?

    def assign_related_objects(received_attrs)
      return true unless new_record?

      self.school = find_school(received_attrs)
      self.user = find_user(received_attrs)
    end

    private def missing_school_or_user?(received_attrs)
      if missing_school?(received_attrs)
        Rails.logger.debug("missing school - attrs: #{received_attrs}")
      end
      if missing_user?(received_attrs)
        Rails.logger.debug("missing user - attrs: #{received_attrs}")
      end
      missing_school?(received_attrs) || missing_user?(received_attrs)
    end

    private def missing_school?(received_attrs)
      received_attrs['school_guid'].nil? ||
        find_school(received_attrs).nil?
    end

    private def missing_user?(received_attrs)
      received_attrs['user_guid'].nil? || find_user(received_attrs).nil?
    end

    private def find_school(received_attrs)
      School.find_by(guid: received_attrs['school_guid'])
    end

    private def find_user(received_attrs)
      User.find_by(guid: received_attrs['user_guid'])
    end
  end
end
