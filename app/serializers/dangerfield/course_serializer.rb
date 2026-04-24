module Dangerfield
  class CourseSerializer < Dangerfield::BaseSerializer
    add_attributes :owner_guid, :school_guid
    exclude_attributes :id, :owner_id, :school_id, :video_subtitle_languages,
                       :video_transcript_languages, :allow_video_popup_translation,
                       :course_package_ids, :share_to_google_classroom, :show_estimated_times,
                       :allows_review_requests, :allows_help_requests, :allow_audio_transcripts,
                       :allow_individual_assign, :hide_from_instructor_dashboard,
                       :enable_vocab_tutorial_translations, :course_config_json,
                       :share_to_portfolio, :portfolio_activity_types

    def owner_guid
      object.owner.guid
    end

    def school_guid
      object.school.guid
    end
  end
end
