class StudentSettingsPresenter
  def initialize(section, program, current_user, request = nil)
    @section = section
    @program = program
    @current_user = current_user
    @request = request
  end

  def student_data
    students.map do |student|
      # Find the student_section_config for the current section from preloaded association
      config_for_section = student.student_section_configs.detect do |config|
        config.section_id == @section.id
      end

      settings = StudentInteractionSettings.new(student, section, config_for_section)

      {
        id: student.id,
        firstName: student.first_name,
        lastName: student.last_name,
        audio_transcript: settings.audio_transcript,
        video_subtitle_languages: settings.video_subtitle_languages,
        video_transcript_languages: settings.video_transcript_languages,
        input_mode: settings.input_mode
      }
    end
  end

  def students
    return @students if defined?(@students)

    @students = Student
                .includes(:enrollments, :student_section_configs)
                .where(enrollments: { section_id: @section.id, state: 'enrolled' })
                .order('users.last_name')
  end

  def section_video_transcript_languages
    @section.video_transcript_languages.presence || @section.course.video_transcript_languages
  end

  def section_video_subtitle_languages
    @section.video_subtitle_languages.presence || @section.course.video_subtitle_languages
  end

  def section_audio_transcript
    @section.audio_transcript.nil? ? @section.course.allow_audio_transcripts : @section.audio_transcript
  end

  def section_input_mode
    @section.input_mode || 'speech'
  end

  def ai_input_modes
    MaestroActivityEngine::ActivityContent::AIVirtualChat::Item::INPUT_MODE_DISPLAY_NAMES
  end

  def ai_input_mode_values
    MaestroActivityEngine::ActivityContent::AIVirtualChat::Item::INPUT_MODES
  end

  def back_to_link
    return rails_url_helpers.instructor_dashboard_path(@program.id) unless @request&.referer

    begin
      referer_uri = URI.parse(@request.referer)

      # Only allow redirects to our own domain
      unless referer_uri.host == @request.host
        return rails_url_helpers.instructor_dashboard_path(@program.id)
      end

      # Return the path directly - Rails routing will handle invalid paths gracefully
      referer_uri.path
    rescue URI::InvalidURIError
      # If referer is malformed, fall back to dashboard
      rails_url_helpers.instructor_dashboard_path(@program.id)
    end
  end

  def rostering?
    # The current user 'rostering?' function doesn't catch common cartridge users on its own.
    @current_user.rostering? || @current_user.cartridge?
  end

  private def rails_url_helpers
    Rails.application.routes.url_helpers
  end

  attr_reader :program, :section
end
