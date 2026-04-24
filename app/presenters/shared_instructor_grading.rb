# Shared between the presenters for grading sets and review work.
module SharedInstructorGrading
  delegate :partner_chat?, :virtual_chat?, :recording_v2?, :composition?,
           :auto_graded?, :true_false_enhanced?, :video_virtual_chat?, :solo_video_recording?,
           :solo_video_recording_or_included_in_multipart_activity?,
           :group_chat?, :ai_virtual_chat?,
           :has_mixed_grading_method?, to: :activity, prefix: true
  delegate :results, to: :current_student_attempt
  delegate :grade_pending?, :rubric_graded?, to: :rubric_instructor_grading

  def response_id(student, question)
    "#{question.label}_student_#{student.id}"
  end

  def question_response_id(question)
    # Wrap for response_id when including class has current_student implemented
    response_id(current_student, question)
  end

  def recording_path(student, question)
    if recording(student, question).present?
      recording(student, question).recording_path
    else
      # We're passing recording_type param to this method because
      # we want to keep separated student recordings from instructor comment recordings
      Recording.new.generate_file_prefix(recording_type = :instructor)
    end
  end

  def feedback
    grading_feedback
  end

  # since the teammate can be in a different section in the same course
  # we need all the sections in the course so we can find the right attempt
  # memoized for QxQ calls from a loop
  def possible_section_ids(student_attempt)
    @possible_section_ids ||= student_attempt.section.course.sections.pluck(:id)
  end

  def teammate_attempt(teammate, student_attempt, activity)
    Attempt.active
           .by_student(teammate)
           .by_section(*possible_section_ids(student_attempt))
           .by_activities(activity)
           .first
  end

  def new_recording?(student, question)
    recording(student, question).blank?
  end

  def recording(student, question)
    feedback.question_recording(student, question.label)
  end
  private :recording

  def partner_chat_view_manager(student, question)
    PartnerChatGradingViewManager.new(self, student, question)
  end

  def solo_video_recording_view_manager(student, question)
    SoloVideoRecordingGradingViewManager.new(self, student, question)
  end

  def group_chat_view_manager(student, question)
    GroupChatGradingViewManager.new(self, student, question)
  end

  def has_student_attachment_for?(question)
    question.class.module_parents.include?(MaestroActivityEngine::ActivityContent::Composition) &&
      current_student_attempt.attachment_for(question.label)
  end

  # Just a wrapper for question_pending? method for student-based grading
  def student_pending_question?(label)
    question_pending?(label, current_student_attempt)
  end

  # Used in question-based grading
  def question_pending?(label, attempt)
    attempt.results.correctness(label) == 'pending'
  end

  def assign_lossless_auth_token?
    activity.smart_book? || activity.ai_virtual_chat?
  end

  private def rubric_instructor_grading
    RubricInstructorGrading.new(
      activity.id,
      current_student_attempt.section&.id,
      current_student_attempt.user_id
    )
  end
end
