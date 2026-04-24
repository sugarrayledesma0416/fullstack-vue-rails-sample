class SectionStudentSettings
  class UserNotFoundError < StandardError; end

  attr_reader :section

  def initialize(section)
    @section = section
  end

  def update_section_defaults(settings, apply_to_all: false)
    ActiveRecord::Base.transaction do
      section.update!(
        audio_transcript: settings[:audio_transcript],
        video_subtitle_languages: settings[:video_subtitle_languages],
        video_transcript_languages: settings[:video_transcript_languages],
        input_mode: settings[:input_mode]
      )

      # If apply_to_all is true, delete all StudentSectionConfig objects for this section
      StudentSectionConfig.where(section_id: section.id).destroy_all if apply_to_all

      settings.slice(
        :audio_transcript,
        :video_subtitle_languages,
        :video_transcript_languages,
        :input_mode
      )
    end
  end

  def update_students(user_ids, settings)
    ActiveRecord::Base.transaction do
      validate_student_existence(user_ids)
      validate_student_enrollments(user_ids)

      # Find all existing configs for these students
      existing_configs = StudentSectionConfig.where(
        user_id: user_ids,
        section_id: section.id
      )

      # Get the set of user_ids that already have configs
      existing_user_ids = existing_configs.pluck(:user_id)

      # Create new configs for students that don't have them
      new_user_ids = user_ids - existing_user_ids
      new_configs = new_user_ids.map do |user_id|
        StudentSectionConfig.new(
          user_id:,
          section_id: section.id,
          audio_transcript: settings[:audio_transcript],
          video_subtitle_languages: settings[:video_subtitle_languages],
          video_transcript_languages: settings[:video_transcript_languages],
          input_mode: settings[:input_mode]
        )
      end

      # Group configs into those to save and those to destroy
      configs_to_save = []
      configs_to_destroy = []

      # Process existing configs
      existing_configs.each do |config|
        config.assign_attributes(
          settings.slice(
            :audio_transcript,
            :video_subtitle_languages,
            :video_transcript_languages,
            :input_mode
          )
        )
        settings_obj = StudentInteractionSettings.new(config.user, section, config)
        if settings_obj.config_matches_effective_defaults?
          configs_to_destroy << config
        else
          configs_to_save << config
        end
      end

      # Filter out new configs that match defaults
      new_configs.reject! do |config|
        settings_obj = StudentInteractionSettings.new(config.user, section, config)
        settings_obj.config_matches_effective_defaults?
      end

      # Bulk destroy configs that match defaults
      if configs_to_destroy.any?
        StudentSectionConfig.where(id: configs_to_destroy.map(&:id)).delete_all
      end

      # Bulk save new configs
      StudentSectionConfig.import(new_configs) if new_configs.any?

      # Bulk update existing configs
      if configs_to_save.any?
        StudentSectionConfig.import(
          configs_to_save,
          on_duplicate_key_update: %i[
            audio_transcript
            video_subtitle_languages
            video_transcript_languages
            input_mode
          ]
        )
      end

      settings.slice(
        :audio_transcript,
        :video_subtitle_languages,
        :video_transcript_languages,
        :input_mode
      )
    end
  end

  private

  def validate_student_existence(user_ids)
    students = User.where(id: user_ids)
    return unless students.count != user_ids.count

    raise UserNotFoundError, 'We couldn\'t find one or more students.'
  end

  def validate_student_enrollments(user_ids)
    enrolled_user_ids = Enrollment.active.where(
      user_id: user_ids,
      section_id: section.id
    ).pluck(:user_id).uniq
    return unless enrolled_user_ids.sort != user_ids.map(&:to_i).uniq.sort

    raise UserNotFoundError, 'One or more students may not be enrolled in this section.'
  end
end
