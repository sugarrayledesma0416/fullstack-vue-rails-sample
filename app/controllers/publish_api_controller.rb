class PublishApiController < ApplicationController
  include HttpBasicAuthHelper

  before_action :http_basic_authenticate
  skip_before_action :verify_authenticity_token

  before_action :validate_environment, only: :qa_activity

  def concept
    options = allowed_params_hash_for(ConceptPublishProcessor)
    response = ConceptPublishProcessor.new(options).process_request
    generate_formatted_response(response)
  end

  def media_item
    options = allowed_params_hash_for(MediaItemPublishProcessor)
    response = MediaItemPublishProcessor.new(options).process_request
    generate_formatted_response(response)
  end

  def unit
    options = allowed_params_hash_for(UnitPublishProcessor)
    response = UnitPublishProcessor.new(options).process_request
    generate_formatted_response(response)
  end

  def lesson
    options = allowed_params_hash_for(LessonPublishProcessor)
    response = LessonPublishProcessor.new(options).process_request
    generate_formatted_response(response)
  end

  def activity
    options = allowed_params_hash_for(ActivityPublishProcessor)
    response = ActivityPublishProcessor.new(
      options.merge('perform' => params['perform'])
    ).process_request
    generate_formatted_response(response)
  end

  def unlisted_activity
    options = allowed_params_hash_for(UnlistedActivityPublishProcessor)
    response = UnlistedActivityPublishProcessor.new(
      options.merge('perform' => params['perform'])
    ).process_request
    generate_formatted_response(response)
  end

  def qa_activity
    publisher = QaActivityPublisher.new(params[:activity_id], params[:content_xml])
    publisher.publish
    if publisher.error
      render json: { error: publisher.error }, status: :unprocessable_entity
    else
      render json: { filepath: publisher.filepath }, status: :ok
    end
  end

  def after_publish_actions
    LearningTracksExporterWorker.perform_async(params[:program_id])
    render json: {}
  end

  private def generate_formatted_response(api_response)
    respond_to do |format|
      format.html { render plain: api_response.message.inspect, status: api_response.status }
      format.json { render json: api_response.message, status: api_response.status }
    end
  end

  private def allowed_params_hash_for(klass)
    # required attributes: all keys used in publish process logic.
    # valid attributes: all keys used *to create* the published element.
    allowed_keys = (klass::REQUIRED_ATTRIBUTES + klass::VALID_ATTRIBUTES).uniq.sort

    params.permit(*allowed_keys).to_h
  end

  private def validate_environment
    # rubocop:disable Rails/UnknownEnv
    return unless Rails.env.live?
    # rubocop:enable Rails/UnknownEnv

    render(
      json: { error: 'Cannot publish qa activity to live server' },
      status: :unprocessable_entity
    )
  end
end
