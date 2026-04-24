class GradingSet < ApplicationRecord
  belongs_to :program
  belongs_to :instructor, foreign_key: 'user_id'
  belongs_to :activity

  scope :by_program, ->(program) { where(program_id: program) }
  scope :by_instructor, ->(instructor) { where(user_id: instructor) }
  scope :by_activity, ->(activity) { where(activity_id: activity) }

  def self.by_program_and_instructor_and_activity(program, instructor, activity)
    # this finder has a corresponding unique index, so we can get just the first element
    self.by_program(program).by_instructor(instructor).by_activity(activity).first
  end

  def complete?(student_sections)
    grading_status_of_students(student_sections).all? {|pairs| pairs[1][:status_class] == 'complete' }
  end

  def self.create_or_update(user_id, params, student_ids)
    grading_set = where(
      activity_id: params[:activity_id],
      program_id: params[:program_id],
      user_id: user_id
    ).first

    student_id_list = student_ids.uniq.join(',')

    if grading_set
      grading_set.update!(student_id_list: student_id_list)
      grading_set
    else
      GradingSet.create!(
        activity_id: params[:activity_id],
        program_id: params[:program_id],
        show_comments: params[:show_hide_comments],
        student_id_list: student_id_list,
        user_id: user_id
      )
    end
  end

  def students_to_grade(sections)
    eligible_ids = Enrollment
                   .active_or_completed_in_editable_course_by_section(sections)
                   .where(user_id: student_ids)
                   .pluck(:user_id)
                   .uniq

    student_hash_map = Student.where(id: eligible_ids).index_by(&:id)
    student_ids.map { |id| student_hash_map[id] }.compact
  end

  def student_list
    @student_list ||= Student.find(student_ids)
  end

  def grade_all_full_credit(sections:, cartridge_params:, students: student_list)
    attempts = Attempt.find_submitted_attempts_for_activities(students, sections, [activity])
    attempts.each do |attempt|
      attempt.instructor_graded_questions.each do |question|
        if attempt.feedback_item(question.label).nil? || attempt.feedback_item(question.label).points_earned.nil?
          FeedbackItem.submit(
            student: attempt.student,
            section: attempt.section,
            activity: attempt.activity,
            points_earned: question.points_possible,
            question_label: question.label,
            attempt: attempt,
            cartridge_params: cartridge_params
          )
        end
      end
    end
  end

  def comment_all(comment:, sections:, cartridge_params:, students: student_list)
    attempts = Attempt.find_submitted_attempts_for_activities(students, sections, [activity])
    attempts.each do |attempt|
      FeedbackItem.submit(
        student: attempt.student,
        section: attempt.section,
        activity: attempt.activity,
        comment: comment,
        attempt: attempt,
        cartridge_params: cartridge_params
      )
    end
  end

  def update_state(params)
    update(show_comments: params[:show_hide_comments].present?)
    update(show_student_names: params[:show_hide_student_names].present?)
  end

  def grading_status_of_questions(questions)
    attempts = grading_status_attempts(student_sections)
    FeedbackItem.find_number_of_students_graded_for_questions(questions, attempts)
                .each_with_object({}) do |(label, num_graded), memo|
      if activity.smart_book?
        # How many students answered this question.
        num_submitted = smartbook_question_answered_by_student_count(attempts, label)
        # If the question is auto graded, consider that all students are graded.
        question = questions.detect { |question| question.label == label }
        num_graded = num_submitted if question.auto_graded?
      else
        num_submitted = student_ids.size
      end

      memo[label] = grading_status(
        num_submitted: num_submitted,
        num_graded: num_graded
      )
    end
  end

  private def student_sections
    @student_sections ||= Student.find(student_ids).map do |student|
      student.current_section_in_program(program)
    end.compact.uniq
  end

  private def grading_status_attempts(sections)
    @grading_status_attempts ||= Attempt.find_attempts_for_activities(
      student_ids, sections, [activity],
      status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED]
    ).to_a
  end

  private def grading_status(num_submitted:, num_graded:)
    case num_graded
    when 0
      { status_class: 'ungraded', remaining: (num_submitted - num_graded) }
    when num_submitted
      { status_class: 'complete', remaining: 0 }
    else
      # This is a temp fix (MAE-14441) in order to display a complete status despite having
      # more questions graded than actual questions for the activity. This to avoid confusing
      # instructors thinking the app isn't saving their scores and comments.
      # The actual fix for this is described on MAE-14489.
       if num_graded > num_submitted
        { status_class: 'complete', remaining: 0 }
      else
        { status_class: 'incomplete', remaining: (num_submitted - num_graded) }
      end
    end
  end

  # Find the number of students who submitted that question
  private def smartbook_question_answered_by_student_count(attempts, label)
    attempts.count do |attempt|
      attempt.smartbook_responses.answered_by_label.key?(label)
    end
  end

  def points_earned_for_student_on_question(question, student, section)
    attempt = Attempt.find_by_student_section_and_activity(student, section, activity)
    feedback_points_record = FeedbackItem.find_student_points_earned_for_question(question, student.id, attempt)
    feedback_points_record.points_earned if feedback_points_record
  end

  def comment_for_student_on_question(question, student, section)
    attempt = Attempt.find_by_student_section_and_activity(student, section, activity)
    feedback_comment_record = FeedbackItem.find_comment_for_question(question, student.id, attempt)
    feedback_comment_record.comment if feedback_comment_record
  end

  def inline_corrections_for_student_on_question(question, student, section)
    attempt = Attempt.find_by_student_section_and_activity(student, section, activity)
    feedback_inline_corrections_record = FeedbackItem.find_inline_corrections_for_question(question, student.id, attempt)
    feedback_inline_corrections_record.inline_corrections if feedback_inline_corrections_record
  end

  def feedback_for_student_on_question(question, student, section)
    attempt = Attempt.find_by_student_section_and_activity(student, section, activity)
    feedback = FeedbackItem.find_corrections_and_comment_and_points_earned_and_recording_for_question(question, student.id, attempt)
    feedback
  end

  def grading_status_of_students(student_sections)
    questions = activity.instructor_graded_questions
    attempts = grading_status_attempts(student_sections)
    FeedbackItem.find_number_of_questions_graded_for_students(student_ids, attempts, questions)
      .each_with_object({}) do |(student_id, count), memo|
      memo[student_id] = grading_status(
        num_submitted: questions.size,
        num_graded: count
      )
    end
  end

  def owned_by?(user)
    user_id == user.id
  end

  def first_gradable_student(student_sections)
    status = grading_status_of_students(student_sections)
    first_gradable = student_ids.detect { |id| status[id.to_s][:status_class] != 'complete' }
    (first_gradable == student_ids.first ? nil : first_gradable)
  end

  def student_ids
    if student_id_list
      student_id_list.split(',').collect{|id| id.to_i}.uniq
    else
      []
    end
  end
end
