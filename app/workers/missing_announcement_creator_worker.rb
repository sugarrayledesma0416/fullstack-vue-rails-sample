class MissingAnnouncementCreatorWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: true, queue: :high_priority, failures: :exhausted

  def perform(student_id, section_id)
    @student_id = student_id
    @section_id = section_id
    return unless section

    Announcement.create_missing_notifications_for_student_in_section(student, section)
  end

  def student
    Student.find(@student_id)
  end

  def section
    Section.find_by(id: @section_id)
  end
end
