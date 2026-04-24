module QuestionBanks
  module LanguageSwitching
    def add_lang_spans(original_text, main_lang)
      lang_spans = original_text.scan(/\+\+[^\+]*\+\+/)

      # If the main language for the current field is a foreign language,
      # then switch to english when encountering language-switching delimiters.
      # Otherwise, switch to english.
      new_lang = (main_lang == 'en' ? language_code : 'en')

      # When switching to english, italicize the english text. When switching
      # to a foreign language, boldface it.
      style = (new_lang == 'en' ? 'i' : 'b')

      # Copy the original to avoid mutating.
      original_text.dup.tap do |new_text|
        lang_spans.each do |span|
          new_text.sub!(span, new_span(span, new_lang, style))
        end
      end
    end

    private def new_span(old_span, lang, style)
      # Drop the leading and trailing plus-signs.
      contents = old_span[2..-3]
      %(<span lang="#{lang}"><#{style}>#{contents}</#{style}></span>)
    end

    private def language_code
      if respond_to?(:metadata)
        metadata[:language_code]
      else
        raise(
          NotImplementedError,
          'classes that include LanguageSwitching must define either ' \
          'metadata or language_code method'
        )
      end
    end
  end
end
