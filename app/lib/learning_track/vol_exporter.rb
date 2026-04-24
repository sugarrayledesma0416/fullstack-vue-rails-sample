module LearningTrack
  class VolExporter < Base

    def learning_tracks_directory
      file_path('')
    end

    def learning_track_files
      s3_bucket.directory_files(learning_tracks_directory)
    end

    def group_set_files
      learning_track_files.select do |file|
        file.key =~ /group_set/
      end
    end

    def track_family_spreadsheets
      learning_track_files.select do |file|
        file.key =~ /track_specs/
      end
    end

    def categories_json
      s3_bucket.fetch(file_path('categories.json'))
    end

    def write_activities_json
      tracks = {}
      learning_track_files.each do |file|
        if file.key =~ /_#{program.id}.json/
          new_track = JSON.parse(s3_bucket.fetch(file.key))
          new_track_name = new_track.keys.first
          if tracks.has_key?(new_track_name)
            tracks[new_track_name]["subtracks"].merge!(new_track[new_track_name]["subtracks"])
          else
            tracks.merge!(new_track)
          end
        end
      end

      # sort subtracks and tracks
      tracks.each do |k, v|
        tracks[k]["subtracks"] = Hash[v["subtracks"].sort_by { |k_2, v_2| v_2["rank"] }]
      end

      tracks = Hash[tracks.sort_by { |k, v| v["rank"] }]

      result = ActivityExporter.new(program).new_activities_hash
      result.merge!(JSON.parse(categories_json))
      result.merge!({
        'tracks' => tracks
      })

      s3_bucket.store_file_contents!(activities_json_path, JSON.generate(result))
    end

  end
end
