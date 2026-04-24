module LearningTrack
  class LearningTrackFileCreator
    attr_accessor :tracks, :program, :vol_program

    def initialize(program)
      self.program = program
    end

    def self.create(program)
      new(program).create
    end

    def create
      if program.vista_online_learning?
        import_group_set
        export_categories
        export_family_tracks
        vol_program.write_activities_json
      else
        export_activities
      end
    end

    private def vol_program
      @vol_program ||= VolExporter.new(program)
    end

    private def export_activities
      ActivityExporter.new(program).write_activities_json
    end

    private def import_group_set
      group_set_program = GroupSetImporterV2.new(program)
      vol_program.group_set_files.each do |file|
        group_set_program.import(file.key)
      end
    end

    private def export_categories
      CategoryExporter.new(program).write_categories_json('grade_category_set.xlsx')
    end

    private def export_family_tracks
      # We use processed_track_count to know how many which tracks json files with the
      # same track name have been created.
      # The reason is that tracks json files have a consecutive, and to know when to increase
      # to consecutive we need to know if the track_name had been processed.
      processed_tracks_count = Hash.new(0)
      vol_program.track_family_spreadsheets.each do |track_family_filename|
        file_number = track_family_filename.key.match(/_(\d+)\./).captures.last
        track_filename = vol_program.learning_track_files.detect do |file|
          file.key =~ /activities_#{file_number}\./
        end
        if track_filename
          track_program = LearningTrackExporter.new(program)
          track_program.write_learning_track_json(track_filename.key, track_family_filename.key, course_package_ids, processed_tracks_count)
        else
          raise "ERROR: *_activities_#{file_number} needed for #{track_family_filename.key}"
        end
      end
    end

    private def course_package_ids
      Maestro::CoursePackage.all(program.id).map(&:id).join(',')
    end
  end
end
