require 'unicode/emoji'

module EmojiRemovable
  extend ActiveSupport::Concern

  included do
    before_validation :remove_emojis
  end

  private

  def remove_emojis
    attributes_to_clean.each do |attribute|
      value = send(attribute)
      next unless value.is_a?(String)
      send("#{attribute}=", strip_emojis(value))
    end
  end

  def strip_emojis(text)
    return text unless text.is_a?(String)
    return text unless Unicode::Emoji::REGEX.match?(text)

    if text.include?('<') && text.include?('>')
      doc = Nokogiri::HTML::DocumentFragment.parse(text)
      doc.traverse do |node|
        if node.text?
          cleaned_text = clean_emoji_spaces(node.content.gsub(Unicode::Emoji::REGEX, ''))
          node.content = cleaned_text
        end
      end
      doc.to_html.gsub(/>\s+</, '><').strip
    else
      clean_emoji_spaces(text.gsub(Unicode::Emoji::REGEX, ''))
    end
  end

  def clean_emoji_spaces(text)
    lines = text.split(/(\r?\n)/)

    cleaned_lines = lines.map do |line|
      if line.match?(/\r?\n/)
        line
      else
        line.gsub(/[ \t]+/, ' ').strip
      end
    end

    result = cleaned_lines.join

    result.gsub(/[ \t]+/, ' ').strip
  end
end
