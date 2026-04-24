module ActivityRubric
  extend ActiveSupport::Concern

  def set_up_rubric_page
    @page_title = params[:from] == 'grading' ? 'Grade Using Rubric' : 'Rubric'
    @disable_chat_on_page = true
    @no_app_shell = true
    @rubric = @activity.rubric
  end

  def assign_activity_and_rubric_presenter
    set_activity_by_id
    @activity.ensure_correct_version(cms_revision_id) if cms_revision_id

    custom_rubric = CustomRubricLoader.new(
      @activity, current_user, current_section
    )
    custom_rubric.load_xml_from_custom_rubric

    return unless @activity.rubric

    @rubric_presenter = RubricPresenter.new(@activity.rubric, attempt)
  end

  # If a cms_revision_id parameter is specified, use that in preference
  # to doing a lookup. Otherwise, try to find an attempt, and if found,
  # use the cms_revision_id from that attempt.
  private def cms_revision_id
    params[:cms_revision_id] || attempt&.cms_revision_id
  end

  def no_rubric_msg
    'There is no rubric for this activity.'
  end

  private def attempt
    return @attempt if defined?(@attempt)

    @attempt = find_attempt
  end

  private def find_attempt
    if action_name == 'scored_rubric'
      find_completed_student_attempt
    else
      find_current_user_attempt
    end
  end

  private def find_current_user_attempt
    attempts = Attempt.where(
      activity_id: @activity.id,
      section_id: current_section_id,
      user_id: current_user.id
    )
    # In the event of a reset attempt, there will be two attempts. find_by
    # is not reliable for pulling up the completed attempt. Find the completed
    # attempt (not the reset attempt), if there are more than one. There cannot
    # be more than one completed attempt per constraints.
    return attempts.first unless attempts.length > 1

    attempts.detect(&:complete?)
  end

  private def find_completed_student_attempt
    attempts = Attempt.where(
      activity_id: @activity.id,
      section_id: params[:section_id],
      user_id: params[:user_id]
    )
    attempts.detect(&:complete?) || raise(
      StandardError,
      'The completed attempt could not be found.'
    )
  end
end
