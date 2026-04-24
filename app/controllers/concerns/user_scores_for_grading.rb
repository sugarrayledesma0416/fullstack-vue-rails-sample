class UserScoresForGrading
  def initialize(presenter, params, recording_configuration_instance)
    @params = params
    @question = presenter.questions_to_grade.first
    @presenter = presenter
    set_teammates
    @recording_configuration_instance = recording_configuration_instance
  end

  private def chat_type?
    @presenter.activity.partner_chat? || @presenter.activity.group_chat?
  end

  private def set_teammates
    # in the case of partner chat activities, @presenter.teammates is a
    # single ActiveRecord::Relation. Array-ify in this case.
    @teammates = if @presenter.teammates.is_a?(Array)
                   @presenter.teammates
                 elsif @presenter.teammates.is_a?(ActiveRecord::Relation)
                   @presenter.teammates.to_a
                 else
                   [@presenter.teammates.first]
                 end
  end

  private def users_and_view_managers
    # ScoreControlsViewManager provides formatted scoring and recording data
    # at the student/question level, as opposed to the StudentByStudentPresenter,
    # which contains data for all students within a grading set.
    # Loop over users to  build a collection of [<Student>, <ScoreControlsViewManager>] arrays.
    #
    # @teammates is the non-current_student partner/s in chat types, or [] in non chat types.
    # Add current_student to capture all students for this submission.
    @users_and_view_managers ||=
      @teammates.unshift(@presenter.current_student).map do |student|
        next [student, score_controls_view_manager(student)] unless student.instructor?

        # instructor partners do not need a ScoreControlsViewManager
        # because they are not gradable.
        [student, nil]
      end
  end

  private def score_controls_view_manager(student)
    ScoreControlsViewManager.new(
      @question,
      @presenter.feedback.question_feedback(student, @question.label),
      @presenter.feedback.attempt_for_student(student).results,
      @presenter.response_id(student, @question),
      @params
    )
  end

  def comment_boxes
    # Store an array of comment box html for each user.
    # These are rendered in the grading partials and
    # moved to correct the visual location in a Vue onMounted call.

    @comment_boxes ||= users_and_view_managers.map do |user_and_vm|
      user = user_and_vm.first
      next if skip_comment_box?(user)

      instructor_comment_partial(user)
    end.compact
  end

  private def skip_comment_box?(user)
    # instructors, practicing users and users outside of the current instructor's section
    # do not get comment boxes.
    user.instructor? || practicing?(user) || !@presenter.gradeable?(user)
  end

  # rubocop:disable Metrics/MethodLength
  private def instructor_comment_partial(user)
    ActionController::Base.render(
      '/instructor/grading_sets/_all_instructor_comments_rubric_grading.html.erb',
      locals: {
        question: @question,
        response_id: @presenter.response_id(user, @question),
        feedback_item: @presenter.feedback.question_feedback(user, @question.label),
        recording_path: @presenter.recording_path(user, @question),
        is_new_recording: @presenter.new_recording?(user, @question),
        recording_configuration_instance: @recording_configuration_instance,
        comment_box_class: "js-comment-for-#{@question.label}-student-#{user.id}"
      }
    )
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def score_list
    @score_list ||= users_and_view_managers.map do |user_and_vm|
      user, view_manager = *user_and_vm
      # An instructor may complete chat types with student partners.
      if user.instructor?
        {
          user_id: user.id,
          student_name: user.full_name,
          gradable: nil,
          instructor: true,
          practicing: nil,
          comment_box_class: nil,
          attempt_id: nil,
          rubric: nil,
          manual: nil,
          input_name: nil
        }
      else
        format_score_data(user, view_manager)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def format_score_data(user, view_manager)
    gradable = @presenter.gradeable?(user)
    is_practicing = practicing?(user)
    {
      user_id: user.id,
      student_name: user.full_name,
      gradable: gradable,
      instructor: false,
      practicing: is_practicing,
      comment_box_class: comment_box_class(user, gradable, is_practicing),
      attempt_id: @presenter.feedback.attempt_for_student(user).id,
      rubric: view_manager.rubric_criteria_scores,
      # manual score notes:
      # 1) manual score can be an empty string. convert it to nil so it behaves with json parsing.
      # 2) view_manager.question_points will return the sum of any present rubric criteria scores OR
      # a present manual score. Only populate with the question_points if the question
      # has not been rubric graded.
      manual: @presenter.rubric_graded? ? nil : view_manager.question_points.presence,
      input_name: view_manager.score_field
    }
  end
  # rubocop:enable Metrics/MethodLength

  private def comment_box_class(user, gradable, is_practicing)
    return nil unless gradable && !is_practicing

    ".js-comment-for-#{@question.label}-student-#{user.id}"
  end

  private def practicing?(user)
    # never call @presenter.partner_is_practicing? unless chat_type?
    # to avoid a delegation error. partner_is_practicing? delegates to a chat presenter
    # which isn't always present.
    return false unless chat_type?

    @presenter.partner_is_practicing?(user, @presenter.current_student)
  end
end
