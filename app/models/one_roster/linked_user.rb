module OneRoster
  class LinkedUser < ApplicationRecord
    include Dangerfield::Subscriber

    self.table_name = 'one_roster_linked_users'
    subscribe to: self
    self.dangerfield_exclude_on_update = %w[id updated_at created_at school_guid user_guid]
    dangerfield_before_update :assign_related_objects
    dangerfield_reject_if :no_user_added?

    belongs_to :user
    belongs_to :school

    # if this is not a new record returning false will
    # allow dangerfield publishing to proceed;
    # if it is a new record this will ensure that there
    # is a user_guid in the incoming attributes and
    # that the user exists
    def no_user_added?(received_attrs)
      if new_record?
        received_attrs['user_guid'].nil? || User.find_by_guid(received_attrs['user_guid']).nil?
      end
    end

    def assign_related_objects(received_attrs)
      self.user = User.find_by(guid: received_attrs['user_guid'])
      self.school = School.find_by(guid: received_attrs['school_guid'])
    end
  end
end
