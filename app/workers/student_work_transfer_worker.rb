class StudentWorkTransferWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerConflictManagement

  SWT_IN_PROGRESS_KEY = 'StudentWorkTransferWorker'.freeze
  THREE_MINUTES_FROM_NOW = 180

  CONFLICT_KEYS = [GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY].freeze

  sidekiq_options retry: true, failures: :exhausted, queue: :high_priority

  def perform(student_id, section_from_id, section_to_id)
    logger_data_merge(user_id: student_id,
                      section_from_id: section_from_id,
                      section_to_id: section_to_id)
    # ensure there is no conflict with SchoolMerge
    # if there is conflict, we reschedule the job to run again in 3 minutes.
    if conflict?(CONFLICT_KEYS)
      # reschedule in 3 minutes with same params.
      schedule_in_three_minutes(
        student_id,
        section_from_id,
        section_to_id,
        "there is a #{GbSchoolMergeWorker::SCHOOL_UPDATE_IN_PROGRESS_KEY} in progress"
      )
    else
      destination_section = Section.unscoped.find_by(id: section_to_id)
      unless destination_section&.archived?
        destination_gb_section = GradebookEngine::Section.find_by(id: section_to_id)
        if destination_gb_section
          in_progress(SWT_IN_PROGRESS_KEY)
          swt = StudentWorkTransfer.new(student_id, section_from_id, section_to_id)
          swt.process
          logger_data_merge(swt.logger_data)
        else
          # reschedule in 3 minutes with same params.
          schedule_in_three_minutes(
            student_id,
            section_from_id,
            section_to_id,
            "the GradebookEngine::Section record for section_id #{section_to_id} hasn't been created at the moment"
          )
        end
      end
    end
  ensure
    # clear the in-progress flag
    # no matter what happened in the SWT process
    completed_progress(SWT_IN_PROGRESS_KEY)
  end

  private def schedule_in_three_minutes(student_id, section_from_id, section_to_id, reason)
    StudentWorkTransferWorker.perform_in(
      THREE_MINUTES_FROM_NOW,
      student_id,
      section_from_id,
      section_to_id
    )
    logger_data_merge(errors: "re-scheduling to process in 3 minutes, #{reason}")
  end
end
