require_relative 'vol_exporter'

module LearningTrack
  class LearningTrackExporter < VolExporter
    attr_accessor :course_package_ids, :track_family_filepath, :csv_filepath

    def write_learning_track_json(csv_filepath, track_family_filepath, course_package_ids, processed_track_count = Hash.new(0))
      @csv_filepath = csv_filepath
      @track_family_filepath = track_family_filepath
      @course_package_ids = course_package_ids

      # 'track_name' is obtained from a column header inside the activities Excel file
      # send by techProduction to create the learning tracks.
      # For each of this Excel files a JSON file is created, but the same header name can
      # appear in multiple Excel files, because of that, a consecutive is added to the file name.
      # For example: If the header name is "Face-to-Face (Preparatory Model)", and it is present
      # in two Excel files, the code below will create:
      #
      # Face-to-Face (Preparatory Model)(1)_102.json
      # Face-to-Face (Preparatory Model)(2)_102.json
      build_tracks.each do |track_name, track_data|
        normalized_track_name = track_name.gsub(/\//, '_')
        processed_track_count[normalized_track_name] += 1
        track_file_name = "#{normalized_track_name}(#{processed_track_count[normalized_track_name]})_#{program.id}.json"
        puts '==========================='
        puts build_learning_track_json(track_name, track_data).inspect
        puts '==========================='
        s3_bucket.store_file_contents!(file_path(track_file_name),
                                       build_learning_track_json(track_name, track_data))
      end
    end

    def csv
      @csv ||= temp_spreadsheet(csv_filepath)
    end

    def track_family_csv
      @track_family_csv ||= temp_spreadsheet(track_family_filepath)
    end

    def headers
      @headers ||= csv.first.map(&:strip)
    end

    def track_family_headers
      @track_family_headers ||= track_family_csv.first.map(&:strip)
    end

    def activities_from_csv
      @activities_from_csv ||= csv[1..-1].map do |row|
        Hash[headers.zip(row)]
      end
    end

    def track_families_from_csv
      @track_families_from_csv ||= track_family_csv[1..-1].map do |row|
        Hash[track_family_headers.zip(row)]
      end
    end

    def find_group_id(activity, group_set_name, group_name)
      group_set = GroupSet.where(:name => group_set_name).first
      raise(StandardError, "Group Set with name: #{group_set_name} not found.") unless group_set
      track_group = TrackGroup.where(:program_id => program.id,
                                     :lesson_id => activity.lesson_id,
                                     :concept_id => activity.concept_id,
                                     :group_set_id => group_set.id,
                                     :name => group_name,
                                    ).first
      unless track_group
        puts "Track Group with lesson_id: #{activity.lesson_id}, concept_id: #{activity.concept_id}, group_set_id: #{group_set.id}, name: #{group_name} not found for activity_cms_id: #{activity.cms_activity_id}."
        track_group = TrackGroup.create(name: group_name, lesson_id: activity.lesson_id, concept_id: activity.concept_id, group_set_id: group_set.id, program_id: program.id)
      end
      track_group.id
    end

    def check_column(track_family, subtrack_name)
      first_activity = activities_from_csv.first
      unless first_activity.has_key?("#{track_family}: #{subtrack_name}") || first_activity.has_key?("#{track_family}:#{subtrack_name}")
        puts "Column not found for #{track_family}: #{subtrack_name}"
      end
    end

    def build_activities_for_subtrack(track_family, subtrack_name, group_set_name)
      # Returns a build up hash that looks like:
      #{ subtrack_activities: [...], first_unit_id: 1, last_unit_id: 2, strands: [...] }
      check_column(track_family, subtrack_name)
      activities_from_csv.inject({strands: [], subtrack_activities: [], units: []}) do |memo, activity_hash|
        group_name = activity_hash["#{track_family}: #{subtrack_name}"] || activity_hash["#{track_family}:#{subtrack_name}"]
        if group_name.present?
          activity = program.activities.where(:cms_activity_id => activity_hash["cms_activity_id"]).where("toc_location IS NOT NULL").includes(:concept, lesson: :unit).first
          if activity.nil?
            puts "Activity not found for cms_activity_id: #{activity_hash['cms_activity_id'].to_i}"
          else
            memo[:units] << activity.lesson.unit.id
            memo[:strands] << activity.concept.base_name.strip
            memo[:subtrack_activities] << {
              id: activity.id,
              group: group_name.downcase.capitalize,
              group_id: find_group_id(activity, group_set_name, group_name),
              category: activity_hash['gradebook_category']
            }
          end
        end
        memo
      end
    end

    private def strands_in_order
      @strands_in_order ||= program.lessons.max_by { |lesson| lesson.concepts.length }.concepts.map(&:base_name).map(&:strip)
    end

    private def build_subtrack(track_family, row)
      serialized_data_for_subtrack = build_activities_for_subtrack(track_family, row['Track Name'], row['Group Set'])
      sorted_units = sort_units(serialized_data_for_subtrack[:units].uniq)
      {
        activities: serialized_data_for_subtrack[:subtrack_activities],
        course_package_ids: course_package_ids,
        description: row['Track Description'],
        strands: serialized_data_for_subtrack[:strands].uniq.sort_by do |strand|
          if strands_in_order.index(strand).nil?
            strands_in_order.count + 1
          else
            strands_in_order.index(strand)
          end
        end,
        first_unit_id: sorted_units.first.id,
        last_unit_id: sorted_units.last.id,
        units: sorted_units,
        categories: row['GB Category Set'],
        class_types: row['Class Types'],
        rank: row['Subtrack Rank'].to_i
      }
    end

    private def sort_units(unit_ids)
      program.units.find(unit_ids).sort_by { |unit| unit.rank }
    end

    private def build_tracks
      current_track_family = ""
      track_families_from_csv.inject({}) do |memo, row|
        if row['Family']
          current_track_family = row['Family']
          memo[row['Family']] = {
            subtracks: {
              row['Track Name'] => build_subtrack(current_track_family, row)
            },
            description: row['Family Description'],
            rank: row['Family Rank'].to_i
          }
        else
          memo[current_track_family][:subtracks][row['Track Name']] = build_subtrack(current_track_family, row)
        end
        memo
      end
    end

    private def build_learning_track_json(track_name, track_data)
      JSON.generate({
        track_name => track_data
      }.as_json)
    end
  end
end
