class FeatureFlagsController < ApplicationController
  include UnleashContextSetup

  before_action :require_user
  before_action :authorize_feature_flags_access
  before_action :override_unleash_context_for_testing, only: :index

  def index
    @programs = load_available_programs
    @selected_program_id = params[:program_id].presence
    @selected_program = Program.find_by(id: @selected_program_id) if @selected_program_id
    @feature_flags = load_feature_flags_with_status
  end

  private def authorize_feature_flags_access
    unless (current_user.respond_to?(:ai_developer?) && current_user.ai_developer?) ||
           (current_user.respond_to?(:developer?) && current_user.developer?)
      flash[:alert] = 'You are not authorized to view this page'
      redirect_to root_path
    end
  end

  private def load_feature_flags_with_status
    feature_config = load_feature_config
    return [] unless feature_config && feature_config['feature_flags']

    feature_config['feature_flags'].map do |flag_name, config|
      context = build_unleash_context

      {
        name: flag_name,
        description: config['description'],
        default: config['default'],
        type: config['type'],
        environments: config['environments'],
        current_status: get_feature_flag_status(flag_name, context),
        evaluated_for: {
          user_id: current_user&.id&.to_s,
          session_id: session.id,
          environment: Rails.env,
          program_id: @selected_program_id
        }
      }
    end
  end

  private def load_feature_config
    config_file = Rails.root.join('config', 'feature_flags.yml')
    return nil unless File.exist?(config_file)

    YAML.safe_load(File.read(config_file))
  end

  private def override_unleash_context_for_testing
    # The UnleashContextSetup concern will automatically pick up params[:program_id]
    # and include it in the context, so we don't need to do anything special here
  end

  private def build_unleash_context
    # Just use the context built by UnleashContextSetup concern
    # It already handles program_id and language_code from params
    @unleash_context
  end

  private def load_available_programs
    # Load programs accessible to the current user
    # You might want to adjust this based on your authorization logic
    Program.where(is_archived: false).order(:title).pluck(:title, :id)
  end

  private def get_feature_flag_status(flag_name, context)
    return false unless defined?(::UNLEASH)

    ::UNLEASH.is_enabled?(flag_name, context)
  rescue => e
    Rails.logger.error "Error checking feature flag #{flag_name}: #{e.message}"
    false
  end
end
