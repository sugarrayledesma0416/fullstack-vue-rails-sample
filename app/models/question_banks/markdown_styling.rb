module QuestionBanks
  module MarkdownStyling
    private def apply_markdown(original_text)
      apply_bold_styling(apply_italic_styling(original_text))
    end

    private def apply_bold_styling(original_text)
      apply_styling(original_text, /\*\*[^\*]+\*\*/, 'b')
    end

    private def apply_italic_styling(original_text)
      apply_styling(original_text, /__[^_]+__/, 'i')
    end

    private def apply_styling(original_text, regexp, tag)
      spans = original_text.scan(regexp)

      # Copy the original to avoid mutating.
      original_text.dup.tap do |new_text|
        spans.each do |span|
          # Drop the leading and trailing delimiters.
          styled_content = span[2..-3]
          new_text.sub!(span, "<#{tag}>#{styled_content}</#{tag}>")
        end
      end
    end
  end
end
