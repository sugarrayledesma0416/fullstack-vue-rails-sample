class Cartridge::ActivitiesController < ActivitiesController
  include CartridgeViewable

  skip_before_action :set_current_focus, only: :access_denied
  skip_before_action :ensure_can_access_activity, only: :access_denied

  def show
    show_activity(params)
    flash[:notice] = @activity_presenter.flash_notice if @activity_presenter.flash_notice.present?
  end

  def finalize
    common_prep(params) do
      @attempt = @classwork.find_active_attempt(@activity) unless @attempt
      if @attempt
        @activity.ensure_correct_version(@attempt.cms_revision_id)
        @attempt.activity = @activity  # ensure attempt.activity points to the same object
      end
    end

    if @attempt
      if @attempt.mark_as_completed(params[:start_time].to_i, time_now_in_seconds)
        @attempt.propagate_time_spent_to_score
        flash[:notice] = 'Results finalized'
      else
        flash[:error] = 'Problem finalizing results'
      end
      redirect_to(cartridge_section_activity_path(current_section_id, @activity.id))
    else
      flash.delete(:notice)
      flash.now[:error] = active_attempt_error_message
      show_activity(params)
    end
  end

  def access_denied
    activity = Activity.find(params[:id])
    @message = flash[:error] % activity.title
    flash.delete(:error)
    render layout: 'music_v1/default'
  end
end
