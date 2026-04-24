module QuestionBanks
  class MultipleChoiceBinaryBuilder
    include LanguageSwitching
    include MarkdownStyling
    include NoHtmlValidation

    attr_accessor :errors, :exam_reference, :lines, :metadata, :options

    def initialize(exam_reference:, lines:, metadata:, options:)
      self.options = options

      self.exam_reference = exam_reference
      self.lines = lines
      self.metadata = metadata

      self.errors = []
    end

    def valid?
      valid_headers? && valid_fields?
    end

    def content_object
      @content_object ||= activity_class.from_csv_hash(
        direction_line: metadata[:direction_line],
        exam_reference: exam_reference,
        item_data: item_data,
        title: metadata[:title]
      )
    end

    private def item_data
      lines.map.with_index(1) do |line, index|
        {
          choices: choice_data(line),
          number: index,
          prompt: apply_markdown(
            add_lang_spans(line[:prompt], metadata[:prompt_lang])
          )
        }
      end
    end

    private def choice_data(line)
      options.map do |option|
        is_correct = line[:correct_answer] == option
        { is_correct: is_correct, text: option }
      end
    end

    private def valid_headers?
      required_columns.each do |field|
        unless lines.first.headers.include?(field)
          errors << "required column header '#{field}' was not found"
        end
      end
      errors.empty?
    end

    private def valid_fields?
      lines.each.with_index(2) do |line, index|
        required_columns.each do |field|
          prefix = "line #{index}: '#{field}' field"
          validate_not_blank_and_no_html(prefix, line[field])
        end
      end
      errors.empty?
    end

    private def required_columns
      %i[prompt correct_answer]
    end

    private def activity_class
      MaestroActivityEngine::ActivityContent::MultipleChoiceTrueFalseContent
    end
  end
end
