class InstructorGradingSetsPresenter
  include SharedInstructorGrading

  attr_reader :grading_set, :sections, :params, :instructor
  attr_accessor :invalid_scores, :chat_presenter

  delegate :ai_grading_suggestions_enabled?, to: :instructor

  def initialize(instructor, grading_set, program, sections, params, show_auto_graded_questions)
    @instructor = instructor
    @show_auto_graded_questions = show_auto_graded_questions
    @grading_set = grading_set
    @program = program
    @sections = sections
    @params = params
    self.invalid_scores = []
    self.chat_presenter = nil
  end

  def show_auto_graded_questions?
    #always show auto graded questions if the activity type is auto graded
    #show_auto_graded_questions setting is stored as a string of '1' or '0' :(
    activity.auto_graded? || @show_auto_graded_questions == '1'
  end

  def activity
    @activity ||= grading_set.activity
  end

  # Returns true if the AI grading feature is enabled either at the program
  # level or at the instructor account level.
  def ai_grading_feature_enabled?
    @program.ai_grading_feature_enabled? || instructor.can_use_ai_grading_suggestions?
  end

  # Returns true if the AI grading Vue app should be mounted.
  # We always mount it for activities supporting AI grading feature.
  def mount_ai_grading_toggle_app?
    activity.supports_ai_grading_feature?
  end

  def done_early?
    params[:commit] == 'Done' && params[:jump_to].blank?
  end

  def get_grading_list_element(grading_list, current_element, jump_to)
    if jump_to.blank?
      idx = grading_list.index(current_element) + 1 if params[:commit] == 'Save & Next >'
      idx = grading_list.index(current_element) - 1 if params[:commit] == '< Save & Previous'
    else
      idx = grading_list.index(jump_target(grading_list, jump_to))
    end
    (idx && grading_list[ idx ]) || :no_next_element_found
  end

  def students_submitted_multiple_versions?
    student_attempts.collect{|key, val| val.cms_revision_id}.uniq.count != 1
  end

  def students_to_grade
    @students_to_grade ||= @grading_set.students_to_grade(@sections)
  end

  def disable_controls?
    activity.partner_chat? || activity.recording_v2? || activity.group_chat?
  end

  def results_by_response_id
    student_attempts.inject({}) do |memo, (student_id, attempt)|
      questions_to_grade.each{ |question| memo["#{question.label}_student_#{student_id}"] = attempt.results.points_earned(question.label).to_f }
      memo
    end
  end

  def add_attempt_section_when_missing(attempt)
    # It's possible to grade a student that did a partner chat in a
    # section that is NOT in the current focus. In order to gather
    # the correct grading feedback, we must add all the relevant
    # sections.
    # We also have to avoid sections with id 0.
    # Those section will be there for partner_chats with an Instructor.
    if sections.none? { |s| attempt.section_id != 0 && s.id == attempt.section_id }
      sections << attempt.section
    end
  end

  def gradeable?(student)
    attempt = student_attempts[student.id.to_s] || teammate_attempts[student]
    attempt && instructor.gradeable_sections.include?(attempt.section)
  end

  def activity_questions
    @activity_questions ||=
      if activity.santillana?
        # Return all the questions answered by at least one student.
        student_attempts.values.flat_map do |attempt|
          attempt.smartbook_responses.answered
        end.uniq(&:interaction_id).sort
      else
        activity.questions
      end
  end
end
