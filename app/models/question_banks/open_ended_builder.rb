module QuestionBanks
  class OpenEndedBuilder
    include LanguageSwitching
    include MarkdownStyling
    include NoHtmlValidation

    attr_accessor :errors, :exam_reference, :lines, :metadata

    def initialize(exam_reference:, lines:, metadata:)
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
          number: index,
          prompt: apply_markdown(
            add_lang_spans(line[:prompt], metadata[:prompt_lang])
          )
        }
      end
    end

    private def valid_headers?
      required_columns.each do |field|
        unless lines.first.headers.include?(field)
          add_error("required column header '#{field}' was not found")
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
      %i[prompt]
    end

    private def activity_class
      MaestroActivityEngine::ActivityContent::OpenEndedContent
    end
  end
end
