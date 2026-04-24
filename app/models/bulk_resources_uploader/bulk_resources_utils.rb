module BulkResourcesUploader
  module BulkResourcesUtils
    def zip_exist_in_s3?
      s3_bucket.file_exist?(@zip_file_s3_path)
    end

    def csv_exist_in_s3?
      s3_bucket.file_exist?(@csv_s3_path)
    end

    def errors_report_exist_in_s3?
      s3_bucket.file_exist?(@csv_errors_report)
    end

    def fetch_zip
      s3_bucket.fetch(@zip_file_s3_path)
    end

    def fetch_bulk_csv
      s3_bucket.fetch(@csv_s3_path)
    end

    def zip_last_modified
      return unless zip_exist_in_s3?

      s3_bucket.bucket.object(@zip_file_s3_path)
               .last_modified.in_time_zone('Eastern Time (US & Canada)')
               .strftime('%B %d, %Y %I:%M %p')
    end

    def csv_last_modified
      return unless csv_exist_in_s3?

      s3_bucket.bucket.object(@csv_s3_path)
               .last_modified.in_time_zone('Eastern Time (US & Canada)')
               .strftime('%B %d, %Y %I:%M %p')
    end

    def csv_column_extractor(column_key)
      extracted_array = []
      DemoData::CSV.rows(fetch_bulk_csv, true) do |row|
        extracted_array << row[column_key]
      end
      extracted_array
    end

    def create_entries_array
      entries = []
      Zip::File.open_buffer(fetch_zip) do |zip_file|
        entries = zip_file.entries
                          .map { |entry| entry.name.force_encoding('UTF-8') }
                          .reject { |name| name.end_with?('/') }
      end
      entries
    end

    def files_status
      { zip: zip_exist_in_s3?, zip_last_modified:, csv: csv_exist_in_s3?, csv_last_modified: }
    end

    def define_paths
      @zip_file_s3_path = path_creator(:zip_file_s3_path)
      @csv_s3_path = path_creator(:csv_s3_path)
      @unziped_path = path_creator(:unziped_path)
      @csv_errors_report = path_creator(:csv_errors_report)
      @errors = []
      @warnings = []
    end

    def path_creator(path_name)
      return '' if @program_id.nil?

      @path_creator ||= {
        zip_file_s3_path: "#{@root_path}/#{@program_id}/#{@program_id}_m3_resources.zip",
        csv_s3_path: "#{@root_path}/#{@program_id}/#{@program_id}_m3_resources.csv",
        csv_errors_report: "#{@root_path}/#{@program_id}/#{@program_id}_errors_report.csv",
        unziped_path: "#{@root_path}/#{@program_id}/unziped"
      }
      @path_creator[path_name]
    end

    def report_fail(error)
      @tracker.fail!
      @tracker.log('creation_failed', error.message, 0)
    end
  end
end
