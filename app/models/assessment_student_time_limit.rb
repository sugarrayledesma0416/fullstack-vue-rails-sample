class AssessmentStudentTimeLimit < ApplicationRecord
  scope :by_section, ->(section) { where(section_id: section) }
  scope :by_activity, ->(activity) { where(activity_id: activity) }
  scope :by_student, ->(student) { where(user_id: student) }

  def self.student_time_limits(section, activity)
    by_section(section).by_activity(activity)
  end

  def self.student_time_limit(section, activity, student)
    student_time_limits(section, activity).by_student(student).first
  end

  def self.delete_time_limits(section_id, activity_id)
    student_time_limits(section_id, activity_id).each(&:destroy)
  end
end
