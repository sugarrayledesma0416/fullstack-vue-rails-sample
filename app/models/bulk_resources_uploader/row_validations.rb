module BulkResourcesUploader
  module RowValidations
    include UnitAndLessonValidations
    require_relative '../../../lib/tasks/demo_data/csv'

    MANDATORY_FIELDS = %i[source_file_path start_unit component_name clean_title].freeze
    NUMERIC_COLUMNS = %i[end_unit is_student_resource is_protected].freeze
    COLUMNS = %i[source_file_path start_unit end_unit component_name
                 subcomponent_name clean_title is_student_resource
                 is_protected description].freeze

    def validate_rows
      @row_index = 1
      DemoData::CSV.rows(fetch_bulk_csv, true) do |row|
        @current_row = row.to_h.transform_keys { |k| k.to_s.gsub(/\uFEFF/, '').strip.to_sym }
        @row_index += 1
        next if empty_row_detected? || invalid_row_format_detected?

        content_validations
      end
    end

    private def content_validations
      mandatory_fields_validation
      missing_file_validation
      invalid_characters_validation
      unit_out_of_range_validation
      numeric_columns_validation
    end

    private def empty_row_detected?
      return false unless @current_row.values.all?(&:nil?)

      @errors << {
        path: 'N/A',
        message: I18n.t('resources_report.errors.messages.empty_row'),
        row_number: @row_index, type: 'empty_row'
      }
      true
    end

    private def invalid_row_format_detected?
      return false if @current_row.keys.all? { |key| COLUMNS.include?(key.to_sym) || key.empty? }

      @errors << {
        path: @current_row[:source_file_path],
        message: I18n.t('resources_report.errors.messages.invalid_row_format'),
        row_number: @row_index, type: 'invalid_row_format'
      }
      true
    end

    private def numeric_columns_validation
      NUMERIC_COLUMNS.each do |column_symbol|
        next if @current_row[column_symbol].nil? ||
                @current_row[column_symbol].match?(/\A\d+(\.\d+)?\z/)

        @errors << { path: @current_row[:source_file_path],
                     message: I18n.t('resources_report.errors.messages.numeric_column',
                                     field: column_symbol.to_s),
                     row_number: @row_index, type: 'numeric_column' }
      end
    end

    private def mandatory_fields_validation
      MANDATORY_FIELDS.each do |column_symbol|
        next if @current_row[column_symbol].present?

        @errors << { path: @current_row[:source_file_path],
                     message: I18n.t('resources_report.errors.messages.missing_field',
                                     field: column_symbol.to_s),
                     row_number: @row_index, type: 'missing_field' }
      end
    end

    private def missing_file_validation
      file_path = @current_row[:source_file_path]
      return if file_path.nil? || entries.include?(file_path)

      path = @current_row[:source_file_path]
      file_name = File.basename(path)
      @errors << {
        path:,
        message: I18n.t('resources_report.errors.messages.file_not_found', file_name:),
        row_number: @row_index, type: 'file_not_found'
      }
    end

    private def invalid_characters_validation
      return if @current_row[:source_file_path].nil?

      original_filename = File.basename(@current_row[:source_file_path])
      comparison_filename = original_filename
                            .remove_accents
                            .tr(' ', '_')
                            .gsub(%r{[<>|/:()&;#?*]}, '-')
      return if original_filename == comparison_filename

      invalid_characters = original_filename.chars - comparison_filename.chars
      @errors << {
        path: @current_row[:source_file_path],
        message: I18n.t('resources_report.errors.messages.invalid_characters',
                        characters: invalid_characters.uniq.join(' ')),
        row_number: @row_index, type: 'invalid_characters'
      }
    end
  end
end
