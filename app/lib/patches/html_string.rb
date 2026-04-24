# encoding: utf-8
module HTMLStringShortener
  def shorten(target_length = 20, trail_char = '&hellip;')
    target_length = target_length.to_i

    if target_length && target_length > 0 && self.length > target_length
      node = Nokogiri.HTML('<div>' + self + '</div>').xpath('//body/div').children
      str, new_length = node_shortener(node, target_length)

      trail_char = trail_char.blank?  ? '' : trail_char.html_decode

      (str || '') + trail_char
    else
      self
    end
  end

  private

  def nodeset_shortener(element, target_length)
    str, new_str_len = '', 0

    element.each do |ele|
      str_l, str_len = node_shortener(ele, target_length)
      if str_len == 0
        break
      end

      target_length -= str_len
      new_str_len += str_len
      str << str_l

      if target_length <= 0
        break
      end

    end

    [str, new_str_len]
  end

  def text_shortener(element, target_length)
    str, str_len = '', 0
    str << element.text.scan(/./mu)[0, target_length].join
    str_len = str.length
    [str, str_len]
  end

  def element_shortener(element, target_length)
    str, str_len = node_shortener(element.children, target_length)
    if str_len != 0
      str = start_tag(element) + str + end_tag(element)
    end
    [str, str_len]
  end

  def node_shortener(element, target_length)
    str = ''
    str_len = 0
    if element.is_a?(Nokogiri::XML::NodeSet)
      str, str_len = nodeset_shortener(element, target_length)
    elsif element.is_a?(Nokogiri::XML::Text)
      str, str_len = text_shortener(element, target_length)
    elsif element.is_a?(Nokogiri::XML::Element)
      str, str_len = element_shortener(element, target_length)
    else
      raise "Unsupported Nokogiri Class" unless element.is_a?(Nokogiri::XML::Comment)
    end
    [str, str_len]
  end

  def end_tag(ele)
    "</#{ele.name}>"
  end

  def start_tag(ele)
    "<#{ele.name}>"
  end
end

class HTMLString < String
  include HTMLStringShortener
end

