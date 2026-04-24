module QuestionBanks
  class MultipleChoiceBuilder
    include LanguageSwitching
    include MarkdownStyling
    include NoHtmlValidation

    attr_accessor :choices, :errors, :exam_reference, :lines, :metadata

    def initialize(choices:, exam_reference:, lines:, metadata:)
      self.choices = choices

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
          # Randomize the choices so that the correct answer isn't
          # always the first choice.
          choices: choice_data(line).shuffle,
          number: index,
          prompt: apply_markdown(
            add_lang_spans(line[:prompt], metadata[:prompt_lang])
          )
        }
      end
    end

    private def choice_data(line)
      [
        {
          is_correct: true,
          text: apply_markdown(
            add_lang_spans(line[:correct_answer], metadata[:choice_lang])
          )
        }
      ] + distractor_data(line)
    end

    private def distractor_data(line)
      required_distractor_columns.map do |field|
        {
          is_correct: false,
          text: apply_markdown(
            add_lang_spans(line[field], metadata[:choice_lang])
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
      end
      errors.empty?
    end

    private def required_columns
      %i[prompt correct_answer] + required_distractor_columns
    end

    # Given 2 choices, require only distractor_1.
    # Given 4 choices, require distractors 1 through 3.
    private def required_distractor_columns
      (1..(choices - 1)).map { |index| "distractor_#{index}".to_sym }
    end

    private def activity_class
      MaestroActivityEngine::ActivityContent::MultipleChoiceContent
    end
  end
end
