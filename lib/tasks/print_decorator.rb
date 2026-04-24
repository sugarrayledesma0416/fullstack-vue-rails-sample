module PrintDecorator

  def print_message(text, header = 'no_header', indent = 0, color = 'none')
    text = case header
      when 'H1' then "====== #{text} ======"
      when 'H2' then "=== #{text} ==="
      when 'H3' then "= #{text} ="
      else text
    end
    color_code = case color
      when 'red'    then 31
      when 'green'  then 32
      when 'yellow' then 33
      when 'blue'   then 36
      else
        37
    end
    indentation = ''
    (0..indent).each{|iteration| indentation = indentation + " "}
    text = indentation + text
    puts "\e[#{color_code}m#{text}\e[0m"
  end

end
