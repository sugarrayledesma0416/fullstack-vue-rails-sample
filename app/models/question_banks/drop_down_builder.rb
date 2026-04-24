module QuestionBanks
  class DropDownBuilder
    ANSWER_REGEXP = /@@menu@@/.freeze

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
          # Randomize the choices so that the correct answer isn't
          # always the first choice.
          choices: choice_data(line).shuffle,
          number: index,
          prompt: apply_markdown(
            add_lang_spans(prompt_data[:prompt], metadata[:prompt_lang])
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

    private def valid_prompt?
      lines.each.with_index(2) do |line, index|
        prefix = "line #{index}: 'prompt' field contains"
        # Find all instances of @@menu@@
        answers = line[:prompt].scan(ANSWER_REGEXP)
        validate_prompt_answers(prefix, answers)
      end
      errors.empty?
    end

    private def validate_prompt_answers(prefix, answers)
      if answers.empty?
        errors << "#{prefix} no menu placeholder (indicated by @@menu@@)"
      elsif answers.size > 1
        errors << "#{prefix} more than one menu placeholder (indicated by @@menu@@)"
      end
    end

    def parse_prompt_data(line)
      # By this point, validation should have ensured that there's exactly one
      # answer.
      delimited_answer = line[:prompt].scan(ANSWER_REGEXP).first
      {
        # Drop the delimiters.
        answer: delimited_answer[1..-2],
        # Replace the delimited answer with a write-on-line element.
        prompt: line[:prompt].sub(delimited_answer, '<wol ref="1" />')
      }
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
      MaestroActivityEngine::ActivityContent::DropDownContent
    end
  end
end
