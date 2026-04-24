module BulkResourcesUploader
  class BulkResourcesCreator
    include BulkResourcesUtils
    include CsvBulkValidator
    include BulkUploadIrs
    include Radner::FilesS3Bucket
    include ActionView::Helpers
    include FileTypeParsable
    require_relative '../../../lib/tasks/demo_data/csv'
    attr_reader :csv_errors_report

    def initialize(program, tracker = nil)
      @program = program
      @program_id = program&.id
      @tracker = tracker
      @root_path = bulk_resources_path
      define_paths
      @units_info = units_info_extractor
    end

    private def units_info_extractor
      return [] if @program.nil? || @program.units.nil? || @program.units.empty?

      @program.units.map do |unit|
        next if unit.nil? || unit.rank.nil?

        {
          unit_rank: unit.rank.to_i + 1,
          lesson_ranks: extract_lesson_ranks(unit)
        }
      end.compact
    end

    private def extract_lesson_ranks(unit)
      return [] if unit.lessons.nil?

      unit.lessons.map do |lesson|
        next if lesson.nil? || lesson.rank.nil?

        lesson.rank.to_i + 1
      end.compact.sort
    end

    def bulk_creation
      unzip
      @tracker.unzipping_completed!
      generate_resources
      @tracker.completed!
    rescue StandardError => e
      report_fail(e)
      raise e
    end

    def unzip
      @tracker.start_unzipping!
      Zip::File.open_buffer(fetch_zip) do |zip|
        zip.each do |entry|
          next if entry.name.end_with?('/')

          file_data = entry.get_input_stream.read
          s3_bucket.store_file_contents("#{@unziped_path}/#{entry.name.force_encoding('UTF-8')}",
                                        file_data)
        end
      end
    end

    def generate_resources
      @tracker.start_creating_resources!
      ActiveRecord::Base.transaction do
        DemoData::CSV.rows(fetch_bulk_csv, true) do |row|
          source_file_path = row[:source_file_path]
          filename = File.basename(source_file_path)
          ext_name = File.extname(filename)
          description = row[:description].present? ? simple_format(row[:description].html_safe, {}, { sanitize: false }) : ''

          parent_component = ResourceComponent
                             .find_or_create_by(name: row[:component_name], program_id: @program_id)

          resource_params = { title: row[:clean_title],
                              program_id: @program_id,
                              file_name: filename,
                              file_type: file_type(ext_name),
                              description:,
                              subcomponent_name: row[:subcomponent_name],
                              vhl_student_resource: (row[:is_student_resource].to_s == '1'),
                              protected: (row[:is_protected].to_s == '1'),
                              resource_component_id: parent_component.id,
                              source: 'VHL' }

          resource_params[:start_unit_id] = unit_for_resource(row[:start_unit])
          resource_params[:lesson_id] = lesson_for_resource(row[:start_unit])
          resource_params[:end_unit_id] = if row[:end_unit].present?
                                            unit_for_resource(row[:end_unit])
                                          end
          resource = Resource.create!(resource_params)
          s3_bucket.move_file("#{@unziped_path}/#{source_file_path}", resource.file_path)
        end
      end
    end

    def unit_for_resource(unit_value)
      raise 'empty unit rank' if unit_value.blank?

      unit_rank = if unit_value.to_s.include?('.')
                    unit_value.split('.').first.to_i
                  else
                    unit_value.to_i
                  end
      unit = Unit.where(rank: (unit_rank - 1), program_id: @program_id).first
      unit&.id
    end

    def lesson_for_resource(start_unit_info)
      return nil unless start_unit_info.to_s.include?('.')

      unit_rank, lesson_rank = start_unit_info.split('.').map(&:to_i)
      unit = Unit.where(rank: (unit_rank - 1), program_id: @program_id).first
      return nil unless unit

      Lesson.where(rank: (lesson_rank - 1), unit_id: unit.id).first&.id
    end
  end
end
