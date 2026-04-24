class InstructorGradingSubmission
  attr_reader :invalid_scores

  def initialize(instructor, activity, students, questions, feedback, student_answers, params)
    @instructor = instructor
    @activity = activity
    @program = activity.program
    @students = students
    @questions = questions
    @feedback = feedback
    @params = params
    @student_answers = student_answers
    @invalid_scores = []
  end

  def process_submission
    return false unless submission_valid?

    @failed_ce_students = Set.new
    @successful_students = Set.new

    student_score_submissions.each do |submission|
      submission.submit
      if submission.concurrent_enrollment_ai_bug_detected
        @failed_ce_students << submission.student.full_name
      else
        @successful_students << submission.student.full_name
      end
    end

    # Always return true unless there are validation errors
    # CE warnings don't block navigation
    true
  end

  def feedback_notification_sent
    student_score_submissions.any?(&:feedback_notification_sent?)
  end

  def has_not_sent_notifications?
    !feedback_notification_sent
  end

  def concurrent_enrollment_failures?
    @failed_ce_students&.any?
  end

  def all_students_failed_ce?
    concurrent_enrollment_failures? && @successful_students&.empty?
  end

  def concurrent_enrollment_warning_message
    return nil unless concurrent_enrollment_failures?

    student_names = @failed_ce_students.join(', ')
    "#{student_names} #{@failed_ce_students.size > 1 ? 'are' : 'is'} enrolled in multiple sections. Navigate to each section to grade submissions."
  end

  def submission_valid?
    return @submission_valid if defined? @submission_valid

    student_score_submissions.each do |submission|
      @invalid_scores << submission.score_field unless submission.valid?
    end

    @submission_valid = @invalid_scores.empty?
  end

  private def student_score_submissions
    return @student_score_submissions if defined? @student_score_submissions

    @student_score_submissions = []
    @students.each do |student|
      @questions.each do |question|
        if question.is_a?(
          MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item
        )
          question.wols.each do |wol|
            @student_score_submissions << create_student_score_submission(student:, question: wol)
          end
        else
          @student_score_submissions << create_student_score_submission(student:, question:)
        end
      end
    end

    @student_score_submissions
  end

  private def create_student_score_submission(student:, question:)
    StudentGradingSubmission.new(
      params: @params,
      student:,
      question:,
      attempt: @feedback.attempt_for_student(student),
      activity: @activity,
      instructor: @instructor,
      grading_feedback: @feedback
    )
  end
end
