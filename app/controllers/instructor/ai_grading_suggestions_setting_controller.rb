class Instructor::AIGradingSuggestionsSettingController < ApplicationController
  include AI::EventTracking

  before_action :require_user
  before_action :require_instructor

  def update
    with_ai_grading_event_tracking('Mid-Grading Toggle AI Setting', tracking_data) do |event|
      current_user.update!(safe_update_params)
      event.extra = {
        state: "toggled_#{current_user.ai_grading_suggestions_enabled? ? 'on' : 'off'}"
      }
    end

    head :ok
  end

  private def tracking_data
    { user: current_user, section: current_section }
  end

  private def safe_update_params
    params.require(:instructor).permit(:enable_ai_grading_suggestions)
  end
end
