module Dangerfield
  class SectionSerializer < Dangerfield::BaseSerializer
    add_attributes :course_guid, :instructor_guid
    exclude_attributes :id, :course_id, :input_mode, :instructor_id, :instructor_team_ids,
      :pronto_enabled, :pronto_enabled_at, :days_to_show_assignment_due_date, :shared,
      :audio_transcript, :video_subtitle_languages, :video_transcript_languages
    def course_guid
      object.course.guid
    end

    def instructor_guid
      object.instructor.guid
    end
  end
end
