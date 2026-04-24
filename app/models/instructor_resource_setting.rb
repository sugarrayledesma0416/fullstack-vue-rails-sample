class InstructorResourceSetting < ApplicationRecord
  belongs_to :resource
  belongs_to :instructor, class_name: 'Instructor', foreign_key: :user_id

  validates_exclusion_of :resource_id, in: [0], message: 'Invalid resource id'

  FRIENDLY_LABELS = { 'shown'     => 'Yes',
                      'hidden'    => 'No',
                      'protected' => 'Never' }.freeze

  def self.settings
    { shown: 'shown', hidden: 'hidden' }
  end

  def destroy_old_settings
    old_settings = InstructorResourceSetting.all_by_user_id_and_resource_id(user_id, resource_id)
    old_settings.each do |old_setting|
      old_setting.destroy
    end
  end

  def self.all_by_user_id_and_resource_id(user_id, resource_id)
    where('user_id = ? and resource_id = ?', user_id, resource_id)
  end

  def shown?
    student_visibility == 'shown'
  end

  def hidden?
    student_visibility == 'hidden'
  end
end
