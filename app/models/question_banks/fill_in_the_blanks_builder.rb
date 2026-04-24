module QuestionBanks
  class FillInTheBlanksBuilder
    ANSWER_REGEXP = /@@[^@]*@@/.freeze
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
      valid_headers? && valid_fields? && valid_prompt?
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
        prompt_data = parse_prompt_data(line)
        {
          answers: [prompt_data[:answer]] + alternate_answers(line),
          number: index,
          prompt: apply_markdown(
            add_lang_spans(prompt_data[:prompt], metadata[:prompt_lang])
          )
        }
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
        prefix = "line #{index}: 'alternates_separated_by_semicolon' field"
        if line[:alternates_separated_by_semicolon].present?
          validate_no_html(prefix, line[:alternates_separated_by_semicolon])
        end
      end
      errors.empty?
    end

    private def valid_prompt?
      lines.each.with_index(2) do |line, index|
        prefix = "line #{index}: 'prompt' field contains"
        # Find all instances of a pair of @ characters with either
        # something inside them, or with nothing inside them. The latter
        # allows notifying about blanks with no answer specified.
        answers = line[:prompt].scan(ANSWER_REGEXP)
        validate_prompt_answers(prefix, answers)
      end
      errors.empty?
    end

    def parse_prompt_data(line)
      # By this point, validation should have ensured that there's exactly one
      # answer.
      delimited_answer = line[:prompt].scan(ANSWER_REGEXP).first
      {
        # Drop the delimiters.
        answer: delimited_answer[2..-3],
        # Replace the delimited answer with a write-on-line element.
        prompt: line[:prompt].sub(delimited_answer, '<wol ref="1" />')
      }
    end

    # Returns an empty array if there are no alternate answers.
    # Throws out the contents between two semicolons with only
    # whitespace inside.
    private def alternate_answers(line)
      line[:alternates_separated_by_semicolon].to_s.split(';').map(&:strip).reject(&:blank?)
    end

    private def validate_prompt_answers(prefix, answers)
      if answers.empty?
        errors << "#{prefix} no answer (delimited with @@)"
      elsif answers.size > 1
        errors << "#{prefix} more than one answer (delimited with @@)"
      elsif answers.first == '@@@@'
        errors << "#{prefix} an empty answer ('@@@@')"
      end
    end

    private def required_columns
      %i[prompt]
    end

    private def activity_class
      MaestroActivityEngine::ActivityContent::FillInTheBlanksContent
    end
  end
end
