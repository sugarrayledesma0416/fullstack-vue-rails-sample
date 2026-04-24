class StudentInteractionSettings
  attr_reader :user, :section

  def initialize(user, current_section, preloaded_config = nil)
    @user = user
    @section = current_section
    @preloaded_config = preloaded_config
  end

  def current_student_section_config
    @current_student_section_config ||= @preloaded_config || StudentSectionConfig.find_by(
      user_id: user.id,
      section_id: section.id
    )
  end

  def input_mode
    current_student_section_config&.input_mode || effective_default_input_mode
  end

  def audio_transcript
    if current_student_section_config.present? && !current_student_section_config.audio_transcript.nil?
      current_student_section_config.audio_transcript
    elsif !section.audio_transcript.nil?
      section.audio_transcript
    else
      course_audio_transcript
    end
  end

  def video_subtitle_languages
    current_student_section_config&.video_subtitle_languages ||
      section.video_subtitle_languages ||
      course_video_subtitle_languages
  end

  def video_transcript_languages
    current_student_section_config&.video_transcript_languages ||
      section.video_transcript_languages ||
      course_video_transcript_languages
  end

  def course_audio_transcript
    return false unless section.course

    section.course.allow_audio_transcripts?
  end

  def course_video_subtitle_languages
    return 'foreign' unless section.course

    section.course.video_subtitle_languages
  end

  def course_video_transcript_languages
    return 'none' unless section.course

    section.course.video_transcript_languages
  end

  def effective_default_input_mode
    section.input_mode || 'speech'
  end

  def effective_default_audio_transcript
    section.audio_transcript.nil? ? course_audio_transcript : section.audio_transcript
  end

  def effective_default_video_subtitle_languages
    section.video_subtitle_languages.nil? ? course_video_subtitle_languages : section.video_subtitle_languages
  end

  def effective_default_video_transcript_languages
    section.video_transcript_languages.nil? ? course_video_transcript_languages : section.video_transcript_languages
  end

  # Returns true if the config matches the effective defaults.  Returns false if any part of the
  # config does not match its corresponding effective default.
  def config_matches_effective_defaults?
    # If there is no config, then that means it "matches" the defaults.
    return true unless current_student_section_config

    # For each setting, it "matches" if it is nil or if it matches the effective default.
    (
      current_student_section_config.audio_transcript.nil? ||
      current_student_section_config.audio_transcript == effective_default_audio_transcript
    ) && (
      current_student_section_config.video_subtitle_languages.nil? ||
      current_student_section_config.video_subtitle_languages == effective_default_video_subtitle_languages
    ) && (
      current_student_section_config.video_transcript_languages.nil? ||
      current_student_section_config.video_transcript_languages == effective_default_video_transcript_languages
    ) && (
      current_student_section_config.input_mode.nil? ||
      current_student_section_config.input_mode == effective_default_input_mode
    )
  end
end
