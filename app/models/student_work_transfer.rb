class StudentWorkTransfer
  ATTRIBUTES_TO_TRANSFER = %w(points_earned points_earned_credit submitted_at
                              pending time_spent grading_status submission_length
                              attempt_count points_pending).freeze

  attr_reader :student, :section_from, :section_to

  def initialize(student, section_from, section_to)
    self.student = student
    self.section_from = section_from
    self.section_to = section_to
  end

  def student=(object_or_id)
    @student = evaluate_by_class(object_or_id, Student)
  end

  def section_from=(object_or_id)
    # if we pass in a zero as an argument, return section zero
    @section_from = object_or_id == 0 && Section.section_zero
    @section_from ||= evaluate_by_class(object_or_id, Section)
  end

  def section_to=(object_or_id)
    @section_to = evaluate_by_class(object_or_id, Section)
  end

  def evaluate_by_class(object, klass)
    if object.instance_of?(klass)
      object
    else
      begin
        klass.find(object)
      rescue ActiveRecord::RecordNotFound
        klass.find_archived(object).first
      end
    end
  end
  private :evaluate_by_class

  def requires_work_transfer?
    student.has_attempts_in_section?(section_from)
  end

  def process
    if current_enrollment.present?
      ActiveRecord::Base.transaction do
        GradebookEngine::ScoreAction.transaction do
          # if section_from is section zero, no transfer
          # remove scores and attempts
          if section_from.zero?
            clear_section_zero_work
          else
            # if the section they are transferring from has any scores, kick
            # off the transfer
            transfer_scores

            # take care of the attempt records
            move_attempts_and_responses

            # ensure we don't leave non-submitted attempts behind
            clean_up_old_attempts

            transfer_standards_results

            transfer_video_chat_work

            transfer_lossless_recordings
          end

          # last step, unblock the enrollment record
          unblock_access!
          logger_data[completed: true]
        end
      end
    else
      raise missing_enrollment_message
    end
  end

  def unblock_access!
    current_enrollment.unblock_access!
  end

  def current_enrollment
    @enrollment ||= student.active_enrollment_by_section(section_to)
  end
  private :current_enrollment

  def missing_enrollment_message
    "StudentWorkTransfer for student_id #{student.id} from section #{section_from.id} \
     failed because student has no active enrollment in new section #{section_to.id}"
  end
  private :missing_enrollment_message

  def time_to_sleep
    time_to_sleep = Rails.env.live? ? 0.5 : 0
  end
  private :time_to_sleep

  def transfer_scores
    return unless section_from && requires_work_transfer?

    GradebookEngine::GradebookAPI.transfer_student_work(user: student,
                                                        section_from: section_from,
                                                        section_to: section_to)
  end
  private :transfer_scores

  private def transfer_standards_results
    StandardsResults.by_student(student).by_section(section_from).each do |standards_result|
      begin
        standards_result.update!(section_id: section_to.id)
      rescue ActiveRecord::RecordNotUnique
        replace_old_standards_result(standards_result)
      end
    end
  end

  private def replace_old_standards_result(replacement_standards_result)
    # find and delete matching standards results from destination section
    StandardsResults.where(
      user_id: replacement_standards_result.user_id,
      cms_activity_id: replacement_standards_result.cms_activity_id,
      section_id: replacement_standards_result.section_id
    ).first.delete
    replacement_standards_result.update!(section_id: section_to.id)
  end

  def move_attempts_and_responses
    Attempt.by_student(student).by_section(section_from).submitted_or_completed.each do |attempt|
      begin
        attempt.update!(section_id: section_to.id)
      rescue ActiveRecord::RecordNotUnique
        replace_old_attempt(attempt)
      end
    end
  end
  private :move_attempts_and_responses

  private def replace_old_attempt(replacement_attempt)
    # find and delete matching attempt from destination section
    Attempt.where(user_id: replacement_attempt.user_id,
                  activity_id: replacement_attempt.activity_id,
                  section_id: section_to.id).first.delete
    replacement_attempt.update!(section_id: section_to.id)
  end

  def clear_section_zero_work
    # using a hard coded zero here to ensure we only affect section zero
    Attempt.where(section_id: 0,
                     user_id: student.id).delete_all
  end

  def clean_up_old_attempts
    Attempt.where(section_id: section_from,
                  user_id: student.id,
                  status_code: [AttemptStatus::CODE_OPENED,
                                AttemptStatus::CODE_RESET,
                                AttemptStatus::CODE_STARTED]).delete_all
  end
  private :clean_up_old_attempts

  def logger_data
    @logger_data ||= {
      user_guid: student.guid,
      section_from_guid: section_from.guid,
      section_to_guid: section_to.guid,
      completed: false
    }
  end

  private def transfer_lossless_recordings
    return if Lossless::Client.new.transfer_student_work(
      student.id, section_from, section_to
    )

    raise StandardError, 'Failed to transfer lossless recordings'
  end

  private def transfer_video_chat_work
    Attempt.by_student(student)
           .by_section(section_to)
           .submitted_or_completed
           .each do |attempt|
      if %w[group_chat partner_chat solo_video_recording].include? attempt.activity.activity_type
        transfer_video_chat_work_record(attempt)
      end
    end
  end

  private def transfer_video_chat_work_record(attempt)
    transfer = StudentVideoChatWorkTransfer.new(
      attempt: attempt,
      new_section_id: section_to.id
    )
    transfer.process

    if transfer.errors?
      raise StandardError, 'Failed to transfer student video chat work: ' \
        "#{transfer.error_messages.join(', ')}."
    end
  end
end
