require 'tempfile'

module LearningTrack
  class Base
    attr_accessor :program

    include Radner::FilesS3Bucket

    def initialize(program)
      self.program = program
    end

    def activities_json_path
      if program.vista_online_learning?
        file_path("#{program.id}.json")
      else
        file_path('activities.json')
      end
    end

    def activities_json
      s3_bucket.fetch(activities_json_path)
    end

    def file_path(file_name)
      server_directory = M3::Application.config.current_deployed_env_name
      "datafiles/#{server_directory}/learning_tracks/#{program.id}/#{file_name}"
    end

    private def temp_spreadsheet(s3_filepath, opts = {})
      temp_file = temp_local_s3_file(s3_filepath)
      parsed_data = parsed_spreadsheet(temp_file, opts)

      temp_file.close
      temp_file.unlink

      parsed_data
    end

    private def temp_local_s3_file(s3_filepath)
      temp_file_name = Pathname.new(s3_filepath).basename.to_s

      Tempfile.new(temp_file_name).tap do |file|
        file.write(s3_bucket.fetch(s3_filepath))
      end
    end

    private def parsed_spreadsheet(temp_file, opts)
      spreadsheet = Roo::Spreadsheet.open(temp_file.path, extension: :xlsx)

      if opts[:headers] == true
        spreadsheet.parse(opts)
      else
        # The first row contains the headers, which are added at the beginning of the parsed data.
        [spreadsheet.row(1)] + spreadsheet.parse(opts)
      end
    end
  end
end
