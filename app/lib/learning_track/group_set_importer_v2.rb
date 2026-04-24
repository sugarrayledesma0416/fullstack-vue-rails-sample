module LearningTrack
  class GroupSetImporterV2 < Base
    attr_accessor :csv, :group_set_name, :headers

    def build_track_groups_from_csv
      csv.map do |row|
        track_group_attrs = Hash[headers.zip(row)]
        # For some reason, roo parses the lesson number as a float and we need an integer string
        lesson_num = track_group_attrs["Lesson"].to_i.to_s
        strand_name = track_group_attrs["Strand"].to_s.strip
        lesson = find_lesson(lesson_num)
        concept = find_concept(strand_name, lesson)
        if lesson.nil?
          puts "Lesson #{lesson_num} not found."
          next
        end
        if concept.nil?
          puts "Concept #{strand_name} not found."
          next
        end
        {
          'lesson_id' => lesson.id,
          'concept_id' => concept.id,
          'name' => track_group_attrs["Group"].to_s.strip,
          'objective' => track_group_attrs["Learning Objective"].to_s.strip,
          'how_to_use' => track_group_attrs["How To Use"].to_s.strip
        }
      end.compact
    end

    def find_lesson(num)
      @lesson_map ||= Hash.new do |hash, key|
        hash[key] = program.lessons.select do |lesson|
          # If a lesson has no label, we try matching on the name
          matched_number = lesson.label.to_s.scan(/\d+/).last || lesson.name.scan(/\d+/).first
          key == matched_number
        end.first
      end
      @lesson_map[num]
    end

    def find_concept(strand_name, lesson)
      if lesson
        squashed_name = squash_name(strand_name)
        lesson.concepts.select do |concept|
          squash_name(concept.name) =~ /#{squashed_name}/
        end.first
      end
    end

    def squash_name(concept_name)
      # Remove all white space, colons, and accents
      ActiveSupport::Inflector.transliterate(concept_name.gsub(/\s+|:/, "")).downcase
    end

    def create_group_set
      GroupSet.where(:name => group_set_name).first ||
        GroupSet.create!(:name => group_set_name)
    end

    def create_track_group(group_set, attributes)
      group_set.track_groups.where(attributes.except('objective', 'how_to_use')).first ||
        group_set.track_groups.create!(attributes)
    end
    private :create_track_group

    def import(csv_s3_file_path)
      @csv = temp_spreadsheet(csv_s3_file_path)
      @group_set_name = csv.shift.compact.last
      #remove headers and use corresponding hard coded ones
      @csv.shift
      @headers = ['Lesson', 'Strand', 'Group', 'Learning Objective', 'How To Use']
      group_set = create_group_set
      build_track_groups_from_csv.each do |track_attributes|
        track_attributes['program_id'] = program.id
        create_track_group(group_set, track_attributes)
      end
    end
  end
end
