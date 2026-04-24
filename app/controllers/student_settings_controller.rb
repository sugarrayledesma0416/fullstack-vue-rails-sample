class StudentSettingsController < RequireInstructorController
  include DateTimeHelper
  include CartridgeViewable

  layout 'application_v3'

  before_action :require_section_access, unless: :current_user_is_institution_admin?

  VALID_LANGUAGE_SETTINGS = %w[none foreign foreign_and_english].freeze

  def show
    @page_title = 'Student Interaction Settings'
    @presenter = StudentSettingsPresenter.new(section, current_program, current_user, request)

    render :student_settings
  end

  def update_section_defaults
    valid_params = validate_update_section_defaults_params

    validation_result = validate_settings(valid_params)
    return render json: validation_result, status: :bad_request if validation_result[:error]

    # Validate apply_to_all boolean
    if valid_params[:apply_to_all].present? &&
       !valid_params[:apply_to_all].in?([true, false])
      return render json: {
        success: false,
        error: 'Please select a valid option for applying to all students.'
      }, status: :bad_request
    end

    begin
      settings = SectionStudentSettings.new(section)
      settings.update_section_defaults(
        valid_params.slice(
          :audio_transcript,
          :video_subtitle_languages,
          :video_transcript_languages,
          :input_mode
        ),
        apply_to_all: valid_params[:apply_to_all]
      )

      @presenter = StudentSettingsPresenter.new(section, current_program, current_user, request)

      render json: {
        success: true,
        message: 'Default settings updated successfully.',
        students: @presenter.student_data
      }, status: :ok
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid,
           ActiveRecord::RecordNotFound => e
      render json: {
        success: false,
        error: 'We encountered an issue while saving your changes. Please try again.'
      }, status: :internal_server_error
    end
  end

  def update_students
    valid_params = validate_update_student_params

    begin
      user_ids = params.require(:user_ids)
      unless user_ids.is_a?(Array)
        return render json: {
          success: false,
          error: 'Please provide an array of user IDs.'
        }, status: :bad_request
      end
    rescue ActionController::ParameterMissing => e
      return render json: {
        success: false,
        error: 'Please provide all required information to update settings.'
      }, status: :bad_request
    end

    validation_result = validate_settings(valid_params)
    return render json: validation_result, status: :bad_request if validation_result[:error]

    begin
      settings = SectionStudentSettings.new(section)
      config = settings.update_students(
        user_ids,
        valid_params.slice(
          :audio_transcript,
          :video_subtitle_languages,
          :video_transcript_languages,
          :input_mode
        )
      )

      render json: {
        success: true,
        config:
      }, status: :ok
    rescue SectionStudentSettings::UserNotFoundError => e
      render json: {
        success: false,
        error: e.message
      }, status: :not_found
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid,
           ActiveRecord::StatementInvalid => e
      render json: {
        success: false,
        error: 'We encountered an issue while saving your changes. Please try again.'
      }, status: :internal_server_error
    end
  end

  private

  def validate_update_section_defaults_params
    params.permit(
      :audio_transcript,
      :input_mode,
      :video_subtitle_languages,
      :video_transcript_languages,
      :apply_to_all,
      :student_setting # Wrapped params, otherwise ignored
    )
  end

  def validate_update_student_params
    params.permit(
      :input_mode,
      :user_ids,
      :audio_transcript,
      :video_subtitle_languages,
      :video_transcript_languages,
      :student_setting # Wrapped params, otherwise ignored
    )
  end

  def section
    @section ||= Section.find_by(id: params[:section_id])
  end

  def validate_settings(valid_params)
    # Validate input_mode
    if valid_params[:input_mode].present? &&
      !valid_params[:input_mode].in?(MaestroActivityEngine::ActivityContent::AIVirtualChat::Item::INPUT_MODES)
      return {
        success: false,
        error: 'Please select a valid option for input mode.'
      }
    end

    # Validate audio_transcript boolean
    if valid_params[:audio_transcript].present? &&
       !valid_params[:audio_transcript].in?([true, false])
      return {
        success: false,
        error: 'Please select a valid option for audio transcripts.'
      }
    end

    # Validate language settings
    if valid_params[:video_subtitle_languages].present? &&
       VALID_LANGUAGE_SETTINGS.exclude?(valid_params[:video_subtitle_languages])
      return {
        success: false,
        error: 'Please select a valid option for video subtitles.'
      }
    end

    if valid_params[:video_transcript_languages].present? &&
       VALID_LANGUAGE_SETTINGS.exclude?(valid_params[:video_transcript_languages])
      return {
        success: false,
        error: 'Please select a valid option for video transcripts.'
      }
    end

    { success: true }
  end
end
