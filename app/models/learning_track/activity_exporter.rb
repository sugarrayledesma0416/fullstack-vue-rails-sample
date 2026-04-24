module LearningTrack
  class ActivityExporter < Base

    def timings
      @timings = temp_spreadsheet(file_path('timings.xlsx'), headers: true)
    end

    def time_lookups
      # Look up by first four letters of strand name and activity_type
      @time_lookups ||= timings.group_by { |t| [ t["Location"].strip[0..3], t["activity_type"], t["grading_method"] ].compact.map(&:strip) }
    end

    def get_activity_requirements(activity)
      {
        require_microphone: activity.chat_or_recording?,
        require_partner:    activity.partner_chat?,
        instructor_graded:  activity.instructor_graded?
      }
    end

    def build_activities_json
      @activities_json ||= program.activities_with_toc_location.inject({}) do |acc, activity|
        concept = activity.concept
        # A duplicate activity will overwrite the previous one.
        acc[activity.id] = {
          id: activity.id,
          title: activity.title,
          unit_id: activity.lesson.unit_id,
          lesson_name: activity.lesson.name,
          strand_name: concept.name,
          minutes_to_complete: activity.minutes_to_complete,
          strand: concept.base_name.strip,
          substrand: activity.sub_strand ? activity.sub_strand.title : nil,
          activity_requirements: get_activity_requirements(activity),
          activity_type: Activity.humanize_activity_type(activity.activity_type)
        }
        acc
      end
    end

    def build_strands_json
      program.lessons.inject({}) do |memo, lesson|
        lesson.concepts.each do |strand|
          name = strand.base_name.strip
          if memo[name]
            memo[name][:unit_ids] << lesson.unit_id
          else
            memo[name] = {
              name: name,
              color: strand.background_color,
              unit_ids: [lesson.unit_id]
            }
          end
        end
        memo
      end
    end

    def write_activities_json
      s3_bucket.store_file_contents!(activities_json_path, new_activities_json)
    end

    def new_activities_json
      JSON.generate(new_activities_hash)
    end

    def new_activities_hash
      { 'activities' => build_activities_json,
        'strands' => build_strands_json,
        'tracks' => {} }
    end
  end
end
