module UnleashContextSetup
  extend ActiveSupport::Concern

  included do
    before_action :set_unleash_context
  end

  private

  def set_unleash_context
    # Build context with proper Unleash parameter names
    user_id = params[:user_id] || session[:user_id] if (params[:user_id] || session[:user_id]).present?
    program_id = params[:program_id] || current_program&.id if (params[:program_id] || current_program&.id).present?
    language_code = params[:language_code] || current_program&.language_code if (params[:language_code] || current_program&.language_code).present?

    # Create properties hash for additional context (using camelCase as expected by Unleash)
    properties = {}
    properties[:programId] = program_id.to_s if program_id.present?
    properties[:languageCode] = language_code if language_code.present?

    Rails.logger.info("Creating Unleash context with user_id: #{user_id}, properties: #{properties}")

    @unleash_context = Unleash::Context.new(
      sessionId: session.id,
      remoteAddress: request.remote_ip,
      userId: user_id,
      properties: properties
    )
  end
end
