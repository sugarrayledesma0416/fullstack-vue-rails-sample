module DictionaryEntriesExport
  module ErrorsExporter
    SUPPORTED_ACTIVITY_TYPES = %w[
      dictionary_flashcards
      grouped_vocab
      hotspots
      learning_engine
      reference_activity
      speech_rec_listen_repeat
      vocab_list
      vocab_list_v2
      vocabulary_tutorial
      vocabulary_tutorial_v2
    ].freeze
    ERRORS_REPORT_HEADERS = %w[step error_message]

    attr_reader :pre_process_errors

    def pre_process_validation
      @pre_process_errors = []
      validate_unsupported_activity_types
      activity_presence_in_program(@cms_activity_ids) if book_exist_in_m3?
      @pre_process_errors
    end

    def book_exist_in_m3?
      book = Program.find_by(id: @program_id)
      return true if book.present?

      @pre_process_errors << "Program #{@program_id} is not present in M3."
      false
    end

    def validate_unsupported_activity_types
      @cms_activity_ids.each do |cms_activity_id|
        activity = first_activity_in_program(cms_activity_id, @program_id)

        next unless activity

        activity_type = activity.activity_type
        unless SUPPORTED_ACTIVITY_TYPES.include?(activity_type)
          message = "Unsupported activity type '#{activity_type}' for dictionary entries report."
          @pre_process_errors << message
        end
      end
    end

    def activity_presence_in_program(activity_ids)
      program = Program.find(@program_id)
      activity_ids.each do |activity_id|
        unless program.activities.pluck(:cms_activity_id).include?(activity_id.to_i)
          message = "Activity #{activity_id} is not present in program #{@program_id}."
          @pre_process_errors << message
        end
      end
    end

    def errors_export
      csv_content = StringIO.new
      CSV.generate(csv_content.string) do |csv|
        csv << ERRORS_REPORT_HEADERS
        @errors.each do |error|
          csv << [error[:step], error[:message]]
        end
        csv_content.rewind
        upload_file_no_cache(csv_content)
      end
    end

    def found_errors?
      csv_parsed_data = CSV.parse(content_data, headers: true)
      csv_parsed_data.headers == ERRORS_REPORT_HEADERS
    end
  end
end
