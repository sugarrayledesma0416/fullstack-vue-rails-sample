module LearningTrack
  class GroupSetImporter
    attr_accessor :csv, :group_set_name, :headers, :program

    def initialize(csv_filepath, program_id)
      @program = Program.find(program_id)
      @csv ||= Roo::Spreadsheet.open("#{csv_filepath}").parse
      @group_set_name ||= csv.shift.compact.last

      #remove headers and use corresponding hard coded ones
      @csv.shift
      @headers = ['lesson_id', 'concept_id', 'name', 'objective', 'how_to_use']
    end

    def build_track_groups_from_csv
      csv.map do |row|
        # Drop out lesson names and strand names from csv, which we don't need
        Hash[headers.zip(row.drop(2))]
      end
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

    def import
      group_set = create_group_set
      build_track_groups_from_csv.each do |attributes|
        attributes['program_id'] = program.id
        create_track_group(group_set, attributes)
      end
    end
  end
end
