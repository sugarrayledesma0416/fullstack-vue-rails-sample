class QuestionResultsController < ApplicationController
  include ActivityPreviewable

  before_action :require_user
  before_action :set_current_user
  before_action :assign_activity_dependencies

  def create
    results = InstantFeedbackResults.new(
      activity: @activity,
      attempt: @attempt,
      disable_enhanced_feedback: disable_enhanced_feedback?,
      inputs: params[:inputs]
    )

    render json: results.payload
  end

  # Dependencies include: @activity, @classwork, and @attempt
  # With a preview activity, these will be handled by the
  # set_up_preview_environment in ActivityPreviewable module.
  private def assign_activity_dependencies
    if params[:activity].present?
      set_up_preview_environment
    else
      @classwork = Classwork.new(current_user, current_section_id)
      @activity = Activity.find(params[:activity_id])
      @attempt = @classwork.find_or_new_attempt(@activity)
      @activity.ensure_correct_version(@attempt.cms_revision_id)
    end
  end

  def disable_enhanced_feedback?
    if @attempt.respond_to?(:disable_enhanced_feedback)
      @attempt.disable_enhanced_feedback
    else
      false
    end
  end
end
