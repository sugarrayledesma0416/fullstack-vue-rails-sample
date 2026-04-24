module QuestionBanks
  module NoHtmlValidation
    private def validate_not_blank_and_no_html(label, value)
      # Don't try to validate html if value is nil or empty string.
      if value.blank?
        add_error("#{label} cannot be blank")
      else
        validate_no_html(label, value)
      end
    end

    private def validate_no_html(label, value)
      new_value = value.dup.force_encoding(Encoding::UTF_8)
      old_value = value.dup.force_encoding(Encoding::UTF_8)
      return if new_value == old_value.strip_tags

      add_error(
        "#{label} may not contain html tags, current value: '#{old_value}'"
      )
    end

    private def add_error(message)
      if respond_to?(:errors)
        errors << message
      else
        raise(
          NotImplementedError,
          'classes that include NoHtmlValidation module must implement ' \
          'either add_error or errors methods'
        )
      end
    end
  end
end
