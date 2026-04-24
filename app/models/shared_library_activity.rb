class SharedLibraryActivity < ApplicationRecord
  belongs_to :activity, class_name: 'InstructorCreatedActivity', optional: true
  belongs_to :source_activity, class_name: 'InstructorCreatedActivity'
  belongs_to :school

  validates :source_activity_id, :school_id, presence: true

  def approve_shared_activity
    update(is_shared: true)
  end

  def self.remove_shared_activity(activity)
    where(activity: activity).destroy_all
  end

  def self.cancel_shared_activity_request(source_activity)
    where(source_activity: source_activity, is_shared: false).destroy_all
  end

  def self.assign_activity_copy_id_and_approver(source_activity_id, activity_id, school_id, user_id)
    where(source_activity_id: source_activity_id, school_id: school_id)
      .last
      .update(activity_id: activity_id, institution_admin_approver_id: user_id)
  end

  def self.shared_activity_record(activity_id)
    where(activity_id: activity_id).first
  end

  def self.allow_copy?(activity_id)
    where(activity_id: activity_id).first.allow_copy
  end

  def approve_allow_copy
    update(allow_copy: true)
  end
end
