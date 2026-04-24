module Cartridge
  class ArchiveClosedCoursesWorker
    include Sidekiq::Worker
    include WorkerInstrumentation
    include WorkerConflictManagement

    CC_IN_PROGRESS_KEY = 'ArchiveClosedCoursesWorker'.freeze
    ARCHIVE_THRESHOLD = 7.days.ago.to_date

    def perform
      if conflict?([CC_IN_PROGRESS_KEY])
        logger_data_merge(error_key: CC_IN_PROGRESS_KEY,
                          cc_archive_error: 'job is currently in process')
      else
        begin
          in_progress(CC_IN_PROGRESS_KEY)
          Cartridge::CourseContextDetail.joins(:course).includes(:course, :section)
                                        .where(['courses.end_date < ?', ARCHIVE_THRESHOLD])
                                        .each do |course_context_detail|
            section = course_context_detail.section
            course = course_context_detail.course
            archive_closed_course(course_context_detail: course_context_detail,
                                  course: course,
                                  section: section)
          end
        ensure
          completed_progress(CC_IN_PROGRESS_KEY)
        end
      end
    end

    def archive_closed_course(course_context_detail:, course:, section:)
      ActiveRecord::Base.transaction do
        section&.archive
        course&.archive

        entity_errors = [
          section,
          course
        ].select { |entity| entity&.errors&.present? }

        entity_errors.each do |entity|
          logger_data_merge(error_key: entity.id,
                            cc_archive_error: entity.errors.full_messages.to_sentence)
        end

        raise ActiveRecord::Rollback unless entity_errors.empty?

        course_context_detail.update!(is_archived: true)
      end
    rescue ActiveRecord::RecordInvalid => e
      logger_data_merge(error_key: e.class.name, cc_archive_error: e.message)
    end
  end
end
