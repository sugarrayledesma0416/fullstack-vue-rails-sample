class ProgramSettings
  attr_reader :program_id
  VALID_STANDARD_GRADE_LEVELS = %w(PK K 1 2 3 4 5 6 7 8 9 10 11 12).freeze

  delegate :practice_test_analytics_enabled?, :hide_activities?,
           :hide_my_content?, :vtext_label, :teacher_vtext_label,
           :ai_grading_feature_enabled?, :ai_program_level,
           :allow_assessments_randomization?,
           :question_banks_enabled?, :hide_translation?,
           :vtext, :supported_standard_set_ids, :supported_standard_sets,
           :pmr_standard_reports_allowed?, :standards_settings, :share_to_portfolio?,
           :show_skills_and_refinement_filters?,
           :enable_concurrent_enrollment?,
           to: :program_settings, allow_nil: true

  def initialize(program)
    @program_id = program.id
  end

  def links
    @links ||= settings.select { |setting| setting.type == 'link' }
  end

  def has_vocab_words?
    program_settings && program_settings.vocab_words?
  end

  def has_vocab_definition?
    program_settings && program_settings.vocab_definition?
  end

  def has_vocab_tools?
    program_settings && program_settings.vocab_tools?
  end

  def hide_assessment?
    program_settings && program_settings.hide_assessment?
  end

  def has_assessment?
    !hide_assessment?
  end

  def has_activities?
    !hide_activities?
  end

  def has_my_content?
    !hide_my_content?
  end

  def vocab_tools_label
    if !has_vocab_tools?
      nil
    elsif program_settings.vocab_tools.blank?
      'Vocabulary Tools'
    else
      program_settings.vocab_tools
    end
  end

  def ebook_label
    if use_default_ebook_label?
      'eBook'
    else
      program_settings.ebook
    end
  end

  def use_default_ebook_label?
    program_settings&.ebook.blank?
  end

  def has_speech_rec?
    program_settings && program_settings.speech_rec?
  end

  def has_pronto?
    settings && program_settings.pronto?
  end

  def has_vtext_link?
    program_settings && program_settings.vtext? && program_settings.vtext.url.present?
  end

  def vtext_link
    program_settings.vtext.url if has_vtext_link?
  end

  def vtext_icon
    program_settings&.vtext&.type&.downcase || 'vtext'
  end

  def vtext_description
    if vtext_icon == 'vtext'
      'Interactive virtual textbook'
    else
      'Virtual textbook'
    end
  end

  def has_teacher_vtext_link?
    program_settings && program_settings.teacher_vtext?
  end

  def teacher_vtext_link
    program_settings.teacher_vtext.url if has_teacher_vtext_link?
  end

  def has_study_center?
    program_settings && program_settings.study_center? && has_vocab_tools?
  end

  def content_menu_additional_entries
    program_settings&.content_menu_additional_entries || []
  end

  def has_audio_transcripts?
    program_settings&.audio_transcripts?
  end

  def standard_grade_levels
    return [] unless supported_standard_sets.any?

    min_grade_index = VALID_STANDARD_GRADE_LEVELS.index(
      standards_settings[:min_grade]
    )
    max_grade_index = VALID_STANDARD_GRADE_LEVELS.index(
      standards_settings[:max_grade]
    )
    VALID_STANDARD_GRADE_LEVELS[min_grade_index..max_grade_index]
  end

  private def program_settings
    @program_settings ||= ProgramConfig.currently_active(@program_id)
  end

  private def settings
    (program_settings && program_settings.settings) || []
  end
end
