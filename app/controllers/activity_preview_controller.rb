class ActivityPreviewController < ApplicationController
  include SmartbookActivityViewable
  include ActivityPreviewable
  include Uploadable::Controller

  helper MaestroActivityEngine::ActivitiesHelper

  protect_from_forgery except: :show
  before_action :set_current_user
  before_action :require_user, except: :process_preview
  before_action :set_up_preview_environment, except: %i[index process_preview]

  # dev form for submitting activity preview data
  def index
    render 'activities/preview_form'
  end

  def process_preview
    content = activity_params.delete(:content)
    content_key = Digest::MD5.hexdigest(content)
    content_cache.cache_put(content_key, content, 1.hour.to_i) # 1 hour TTL

    if safe_preview_params_hash[:content_type]
      render json: { preview_url: preview_url(content_key) }, status: 200
    else
      redirect_to preview_url(content_key)
    end
  end

  def show
    assign_presenter_and_lesson_header
    assign_allowed_file_types
    # hide_header removes the book header from the preview
    # mimicing the real activity view
    @hide_header = true

    if @activity.content_object.present?
      flash.now[:notice] = 'CMS Preview'
      render('activities/show', layout: 'layouts/preview_activity')
    else
      raise StandardError, @activity.parse_errors.join(' | ')
    end
  end

  def preview_answer_key
    assign_presenter_and_lesson_header
    @hide_header = true

    if @activity.content_object.present?
      flash.now[:notice] = 'CMS Preview Answer Key'
      render('activities/answer_keys', layout: 'layouts/preview_activity')
    else
      raise StandardError, @activity.parse_errors.join(' | ')
    end
  end

  def preview_rubric
    assign_presenter_and_lesson_header
    # hide_header removes the book header from the preview
    # mimicing the real activity view
    @hide_header = true
    # Set the footer for this smaller view
    @set_footer = true

    if @activity.content_object.present?
      render('activities/preview_rubric', layout: 'layouts/preview_activity')
    else
      raise StandardError, @activity.parse_errors.join(' | ')
    end
  end

  def safe_preview_params_hash
    params.permit(
      :program_id,
      :preview_theme,
      :content_type,
      activity: %i[activity_type content cms_revision_id content_key]
    ).to_h.symbolize_keys
  end
  helper_method :safe_preview_params_hash

  private def preview_url(content_key)
    preview_activity_path(
      activity: activity_params.merge(content_key: content_key),
      program_id: ensure_valid_program_id,
      preview_theme: params[:preview_theme]
    )
  end

  private def ensure_valid_program_id
    # check program availability
    Program.find(params[:program_id])
    # this method call tries to assign a lesson and strand
    # for display purposes and will error if the program's
    # toc is incomplete
    activity_attrs_for_program
    params[:program_id] # no errors so return the original id
  rescue StandardError => e
    79 # set a fallback id for Portales
  end

  private def assign_presenter_and_lesson_header
    @activity_presenter = StudentActivityPresenter.new(
      @activity,
      current_user,
      current_section
    )
    # a little hack so the presenter doesn't try to make an attempt
    # object of its own
    @activity_presenter.instance_variable_set(:@attempt, @attempt)
    @video_settings = @activity_presenter.video_settings
    @lesson_header = @activity_presenter.lesson_header
  end
end
