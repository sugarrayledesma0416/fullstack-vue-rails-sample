module QuestionBanks
  class Importer
    include LanguageSwitching
    include MarkdownStyling
    include NoHtmlValidation

    COMMON_METADATA_HEADERS = %i[
      bank_name
      direction_line
      dl_lang
      item_type
      prompt_lang
    ].freeze
    BINARY_MC_METADATA_HEADERS = %i[option_1 option_2].freeze
    VALID_ITEM_TYPES = %w[
      mc_2
      mc_3
      mc_4
      binary_mc
      dd_2
      dd_3
      dd_4
      fib
      open_ended
    ].freeze

    attr_accessor :csv_filename, :lines, :question_bank, :raw_csv, :user

    def initialize(filename: nil, lines:, question_bank:, raw_csv: nil, user: nil)
      self.csv_filename = filename
      self.lines = lines
      self.question_bank = question_bank
      self.raw_csv = raw_csv
      self.user = user
    end

    def import
      return unless validates_as_parseable?

      if question_bank.errors.empty? && builder.valid?
        save_question_bank
      else
        builder.errors.each { |error| add_error(error) }
      end
    end

    private def builder
      @builder ||= builder_class.new(**builder_data)
    end

    private def save_question_bank
      set_question_bank_content
      question_bank.title = metadata[:bank_name]
      question_bank.changed_by_id = user&.id
      question_bank.upload_filename = csv_filename
      question_bank.uploaded_csv = raw_csv
      question_bank.save
    end

    private def set_question_bank_content
      exam_content_object.activities = [builder.content_object]
      question_bank.content_json = strip_escaped_newlines(
        exam_content_object.to_json(indent: 0)
      )
    end

    private def strip_escaped_newlines(json)
      json.gsub(/ *\\n */, '')
    end

    private def builder_data
      {
        exam_reference: exam_reference,
        lines: parsed_non_header_lines,
        metadata: builder_metadata
      }.merge(choices_data)
    end

    private def builder_metadata
      {
        dl_lang: metadata[:dl_lang],
        prompt_lang: metadata[:prompt_lang],
        choice_lang: metadata[:choice_lang],
        direction_line: parsed_dl,
        language_code: language_code,
        title: metadata[:bank_name]
      }
    end

    private def parsed_dl
      @parsed_dl ||= apply_markdown(
        add_lang_spans(metadata[:direction_line], metadata[:dl_lang])
      )
    end

    private def normal_multiple_choice?
      metadata[:item_type].starts_with?('mc_')
    end

    private def binary_multiple_choice?
      metadata[:item_type] == 'binary_mc'
    end

    private def drop_down?
      metadata[:item_type].starts_with?('dd_')
    end

    private def choices_data
      if normal_multiple_choice? || drop_down?
        { choices: metadata[:item_type].last.to_i }
      elsif binary_multiple_choice?
        { options: [metadata[:option_1], metadata[:option_2]] }
      else
        {}
      end
    end

    private def builder_class
      case metadata[:item_type]
      when 'mc_2', 'mc_3', 'mc_4' then MultipleChoiceBuilder
      when 'binary_mc' then MultipleChoiceBinaryBuilder
      when 'fib' then FillInTheBlanksBuilder
      when 'open_ended' then OpenEndedBuilder
      when 'dd_2', 'dd_3', 'dd_4' then DropDownBuilder
      end
    end

    # Returns an array of hashes. The index starts at 2 so that the line
    # numbers match the CSV line numbers (which are 1-indexed instead of
    # 0-indexed), and line 1 is the headers.
    private def parsed_non_header_lines
      lines[1..-1].map.with_index(2) { |line, index| parse_line(line, index) }
    end

    private def validates_as_parseable?
      valid_metadata?(COMMON_METADATA_HEADERS) &&
      valid_language?(%i[dl_lang prompt_lang]) &&
      valid_item_type? &&
      valid_metadata_for_item_type?
    end

    private def valid_metadata?(fields)
      valid_metadata_headers?(fields) && valid_metadata_fields?(fields)
    end

    # rubocop:disable Style/IfUnlessModifier
    private def valid_metadata_headers?(names)
      all_valid?(names) do |field|
        unless headers.include?(field)
          add_error("required column header '#{field}' was not found")
        end
      end
    end

    private def valid_metadata_fields?(fields)
      all_valid?(fields) do |field|
        prefix = "metadata field '#{field}'"
        value = metadata[field]
        validate_not_blank_and_no_html(prefix, value)
      end
    end
    # rubocop:enable Style/IfUnlessModifier

    private def all_valid?(fields)
      fields.each { |field| yield field }
      question_bank.errors.empty?
    end

    private def valid_item_type?
      unless VALID_ITEM_TYPES.include?(metadata[:item_type])
        valid_types_list = VALID_ITEM_TYPES.join(', ')
        add_error(
          "value '#{metadata[:item_type]}' for metadata field 'item_type' " \
          "is not one of the acceptable types: #{valid_types_list}"
        )
      end
      question_bank.errors.empty?
    end

    private def valid_metadata_for_item_type?
      if normal_multiple_choice? || drop_down?
        valid_metadata?([:choice_lang]) && valid_language?([:choice_lang])
      elsif binary_multiple_choice?
        valid_metadata?(BINARY_MC_METADATA_HEADERS)
      else
        true
      end
    end

    private def valid_language?(fields)
      valid_languages = MaestroActivityEngine::Languages.valid_activity_codes

      fields.each do |field|
        value = metadata[field]
        next if valid_languages.include?(value)

        add_error(
          "value '#{value}' for metadata field '#{field}' is not " \
          "one of the valid language codes: #{valid_languages.join(', ')}"
        )
      end
      question_bank.errors.empty?
    end

    private def metadata
      # Validate here if meta data missing? Or call separate validation
      # method.
      @metadata ||= parse_line(lines[1], 2)
    end

    private def headers
      # Need the .to_s before .to_sym because an empty header field
      # is returned as "nil" instead of empty string.
      @headers ||= CSV.parse_line(lines.first).map { |header| header.to_s.to_sym }
    end

    private def add_error(message)
      question_bank.errors.add(:base, message)
    end

    private def parse_line(line, number)
      CSV.parse_line(ensure_utf8(line, number), headers: headers)
    end

    private def ensure_utf8(line, number)
      if line.is_utf8?
        line
      else
        line.encode('UTF-8', 'Windows-1252')
      end
    rescue StandardError => e
      add_error("UTF-8 conversion failure #{e.inspect} in line #{number}")
    end

    private def exam_content_object
      activity_class = MaestroActivityEngine::ActivityContent::ExamContent
      @exam_content_object ||= activity_class.from_csv_hash(
        direction_line: parsed_dl,
        language: language_code,
        title: metadata[:bank_name]
      )
    end

    private def language_code
      @language_code ||= question_bank.program.language_code
    end

    private def exam_reference
      reference_class = MaestroActivityEngine::ActivityContent::Reference::Exam
      @exam_reference ||= reference_class.from_csv_hash(
        body: parsed_dl,
        header: metadata[:bank_name],
        rank: 1
      )
    end
  end
end
