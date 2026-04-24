module InstitutionalAdmin::EnterpriseCoursesHelper
  def institutional_admin_enterprise_courses_helper_previous_course_data_attributes
    @previous_courses.map { |c|
      [
        c.name, c.id,
        {
          data: {
            first_unit_id: c.first_unit_id,
            last_unit_id: c.last_unit_id,
            enable_vocab_tutorial_translations: c.enable_vocab_tutorial_translations,
            show_estimated_times: c.show_estimated_times,
            allow_individual_assign: c.allow_individual_assign,
            allow_audio_transcripts: c.allow_audio_transcripts,
            video_subtitle_languages: c.video_subtitle_languages,
            video_transcript_languages: c.video_transcript_languages,
            allows_help_requests: c.allows_help_requests,
            allows_review_requests: c.allows_review_requests,
            chat_level: c.chat_level
          }
        }
      ]
    }
  end

  def institutional_admin_enterprise_courses_helper_previous_course_categories_attributes
    @previous_courses.map { |c|
      [
        c.name, c.id,
        {
          data: {
            categories: (c.categories.pluck(:name, :penalty_percent).map { |pair| "#{pair[0]}->#{pair[1]}" }.join(',') rescue [])
          }
        }
      ]
    }
  end
end
