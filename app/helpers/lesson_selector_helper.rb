module LessonSelectorHelper
  # When span tag with lang attribute is presented in the Lesson name, change
  # these to div tags for screen readers and add styling to avoid visible UI changes
  def format_lesson_name_for_screenreader(lesson_name, lesson_language)
    if lesson_name =~ /<span.*?>/
      lesson_name_parts = lesson_name.split(%r{(<span.*?>.*?</span>)})
      result = lesson_name_parts.filter_map do |name|
        lang_value = language_value(name, lesson_language)
        lang_value = lesson_language if lang_value.empty?

        name.gsub!(%r{</?span.*?>}, '')
        cleanup_name(name)
        next if name.empty?

        inline_div_with_lang(lang_value, name)
      end
      result.join
    else
      lesson_name
    end
  end

  private def cleanup_name(name)
    if name.match(%r{<.*?>.*</.*?>})
      name
    else
      name.gsub!(/<.*?>/, '')
      # To avoid injection vulnerability
      name.gsub!(/<|>/, '')
    end
  end

  # If name has '<span lang="es">prueba</span>' string
  # it returns 'es' as language value
  private def language_value(name, lesson_language)
    if name.match(%r{<span\s+lang="[^"]*"\s*>.*</span>})
      name.match(/<span lang="(.*?)">/)&.captures&.first
    else
      lesson_language
    end
  end

  private def inline_div_with_lang(language, content)
    "<div class='u-dis-inline' lang='#{language}'>#{content}</div>"
  end
end
