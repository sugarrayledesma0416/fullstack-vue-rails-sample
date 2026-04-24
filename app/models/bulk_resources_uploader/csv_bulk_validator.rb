require 'zip'
require 'csv'
require 'tempfile'
module BulkResourcesUploader
  module CsvBulkValidator
    include BulkResourcesUploader::RowValidations
    include ActionView::Helpers
    include FileTypeParsable

    def validate_bulk_process
      begin
        raise "This book doesn't have units" if @units_info.empty?

        files_not_used_validation
        duplicated_paths_validation
        validate_rows
      rescue StandardError => e
        unexpected_error(e)
      end
      errors_report_export
      create_response
    end

    private def create_response
      {
        errors_number: @errors.count,
        errors_breakdown:,
        warnings_number: @warnings.count,
        csv_file_name:
      }
    end

    private def csv_file_name
      tracker = setup_tracker(@program_id, processing_files: true)
      if tracker.csv_file_name.present?
        "errors_#{tracker.csv_file_name}"
      else
        'erros_report.csv'
      end
    end

    private def errors_report_export
      errors_headers = %w[row_number path message type]
      csv_content = StringIO.new
      CSV.generate(csv_content.string) do |csv|
        csv << errors_headers
        @errors.each do |error|
          csv << [error[:row_number], error[:path], error[:message], error[:type]]
        end
        csv << ['WARNINGS']
        @warnings.each do |error|
          csv << [error[:row_number], error[:path], error[:message], error[:type]]
        end
        csv_content.rewind
        s3_bucket.store_file_contents(@csv_errors_report, csv_content)
      end
    end

    private def files_not_used_validation
      csv_array = csv_column_extractor(:source_file_path)
      error_paths = entries - csv_array
      error_paths.each do |error_path|
        @warnings << {
          path: error_path,
          message: I18n.t('resources_report.errors.messages.file_not_used',
                          file_name: File.basename(error_path)),
          row_number: 'N/A', type: 'file_not_used'
        }
      end
    end

    private def duplicated_paths_validation
      csv_array = csv_column_extractor(:source_file_path).compact
      duplicated_paths = csv_array.group_by { |path| path }.select { |_, paths| paths.size > 1 }
      duplicated_paths.each_key do |path|
        @errors << {
          path: path,
          message: I18n.t('resources_report.errors.messages.duplicated_path',
                          file_name: File.basename(path)),
          row_number: 'N/A', type: 'duplicated_path'
        }
      end
    end

    private def errors_breakdown
      @errors.group_by { |error| error[:type] }.transform_values do |errors|
        { size: errors.size,
          message: I18n
            .t("resources_report.errors.messages.#{errors.first[:type]}")
            .gsub(/%\{[^}]+\}/, '...') }
      end
    end

    private def unexpected_error(error_message)
      @errors << {
        path: 'N/A',
        message: I18n.t('resources_report.errors.messages.unexpected_error',
                        message: error_message), row_number: 'N/A',
        type: 'unexpected_error'
      }
    end

    private def entries
      @entries ||= create_entries_array
    end
  end
end
