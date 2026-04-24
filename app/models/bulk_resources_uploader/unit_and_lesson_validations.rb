module BulkResourcesUploader
  module UnitAndLessonValidations
    UNIT_FORMAT_REGEX = /^\d+(\.\d+)?$/

    private def unit_out_of_range_validation
      valid_units = @units_info.pluck(:unit_rank)
      validate_start_unit(valid_units)
      validate_end_unit(valid_units)
    end

    private def validate_end_unit(valid_units)
      end_unit = @current_row[:end_unit]&.to_i
      return if end_unit.nil? || valid_units.include?(end_unit)

      add_unit_out_of_range_error(valid_units)
    end

    private def validate_start_unit(valid_units)
      start_unit_info = @current_row[:start_unit]
      return if start_unit_info.blank? || invalid_unit_format?(start_unit_info)

      if start_unit_info.to_s.include?('.')
        validate_unit_with_lesson(start_unit_info, valid_units)
      else
        validate_single_unit(start_unit_info, valid_units)
      end
    end

    private def validate_unit_with_lesson(start_unit_info, valid_units)
      unit_rank, lesson_rank = start_unit_info.split('.').map(&:to_i)
      validate_unit_rank(unit_rank, valid_units)
      validate_lesson_rank(unit_rank, lesson_rank)
    end

    private def validate_single_unit(start_unit_info, valid_units)
      unit_rank = start_unit_info.to_i
      validate_unit_rank(unit_rank, valid_units)
    end

    private def validate_unit_rank(unit_rank, valid_units)
      add_unit_out_of_range_error(valid_units) unless valid_units.include?(unit_rank)
    end

    private def validate_lesson_rank(unit_rank, lesson_rank)
      unit_info = @units_info.find { |u| u[:unit_rank] == unit_rank }
      add_lesson_out_of_range_error unless unit_info&.dig(:lesson_ranks)&.include?(lesson_rank)
    end

    private def add_lesson_out_of_range_error
      @errors << {
        path: @current_row[:source_file_path],
        message: I18n.t('resources_report.errors.messages.invalid_lesson',
                        units_info: @units_info.to_s),
        row_number: @row_index,
        type: 'invalid_lesson'
      }
    end

    private def invalid_unit_format?(unit_info)
      return false if UNIT_FORMAT_REGEX.match?(unit_info.to_s)

      add_invalid_unit_format_error
      true
    end

    def add_unit_out_of_range_error(valid_units)
      @errors << {
        path: @current_row[:source_file_path],
        message: I18n.t('resources_report.errors.messages.unit_out_of_range',
                        range: valid_units.to_s),
        row_number: @row_index,
        type: 'unit_out_of_range'
      }
    end

    private def add_invalid_unit_format_error
      @errors << {
        path: @current_row[:source_file_path],
        message: I18n.t('resources_report.errors.messages.invalid_unit_format'),
        row_number: @row_index,
        type: 'invalid_unit_format'
      }
    end
  end
end
