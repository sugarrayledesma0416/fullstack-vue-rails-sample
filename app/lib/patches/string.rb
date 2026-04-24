# encoding: utf-8

require 'maestro_activity_engine/patches/string'

class String
  def vhl_nl2br  # replaces newlines with br's except within defined html blocks
    tags = %w[article b i ol span table u ul]
    output = ''
    match_tag = ''
    start_tags = Regexp.new("<(#{tags.join('|')})[ \>]" )
    end_tags = Regexp.new("</(#{tags.join('|')})>" )

    str = remove_node_tags(self).strip

    str.split("\n").each do |line|
      line = line.strip

      if match_tag.empty?
        start_tag = start_tags.match(line)
        if start_tag
          match_tag = start_tag[1]
          end_tag = end_tags.match(line)
          if end_tag && end_tag[1] == match_tag
            match_tag = ''
            output += "#{line}<br/>\n"
          else
            output += "#{line}\n"
          end
        else
          output += "#{line}<br/>\n"
        end
      else
        end_tag = end_tags.match(line)
        if end_tag && end_tag[1] == match_tag
          match_tag = ''
        end
        output += "#{line}\n"
      end
    end

    output = output.strip.gsub(/<br\/>\Z/, '')  # no br at the end
    output
  end

  def remove_node_tags(str)
    str.gsub(/(<|<\/)(prompt|body).*?(\/>|>)/, '')
  end

  def shorten(length = 20)
    length = length.to_i
    if length && length > 0 && self.length > length
      self.html_decode.scan(/./mu)[0,length].join + ('&hellip;'.html_decode)
    else
      self
    end
  end

  def combine_overlap(other)
    overlap_index = nil
    other_chars = other.chars.to_a

    self.chars.to_a.each_with_index do |char, index|
      break unless char == other_chars[index]
      overlap_index = index
    end

    return "#{self} - #{other}" unless overlap_index

    "#{self}-#{other[overlap_index+1..-1]}"
  end

  def to_utf8
    encode("UTF-8", "Windows-1252", undef: :replace)
  end
end
