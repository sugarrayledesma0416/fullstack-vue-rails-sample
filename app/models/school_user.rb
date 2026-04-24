require 'institution_admin'

class SchoolUser < ApplicationRecord
  include Dangerfield::Subscriber

  subscribe to: self
  self.dangerfield_exclude_on_update = %w(id updated_at created_at school_guid user_guid)
  dangerfield_before_update :assign_related_objects

  # a new SchoolUser record should not be added if it has not yet added the school or
  # if the user has not yet been added.
  dangerfield_reject_if :no_school_or_no_user_added?

  belongs_to :school
  belongs_to :user
  belongs_to :instructor,
             class_name: 'Instructor',
             foreign_key: 'user_id',
             optional: true

  validates(
    :user_id,
    uniqueness: {
      scope: :school_id,
      case_sensitive: false,
      message: 'You are already registered to this school.'
    }
  )

  def assign_related_objects(received_attrs)
    self.user = User.find_by_guid(received_attrs['user_guid'])
    self.school = School.find_by_guid(received_attrs['school_guid'])
  end

  # reject the SNS push of school user record if either the school or the user
  # is missing from either the incoming parameters or the M3 database
  def no_school_or_no_user_added?(received_attrs)
    no_school_added?(received_attrs) || no_user_added?(received_attrs)
  end

  def no_school_added?(received_attrs)
    received_attrs['school_guid'].nil? || School.find_by_guid(received_attrs['school_guid']).nil?
  end

  def no_user_added?(received_attrs)
    received_attrs['user_guid'].nil? || User.find_by_guid(received_attrs['user_guid']).nil?
  end
end
