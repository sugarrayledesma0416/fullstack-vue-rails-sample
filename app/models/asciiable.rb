module Asciiable
  def ascii
    # if there are any non-ASCII chararcters,
    # return an ASCII transliteration for sorting;
    # otherwise return nil

    I18n.transliterate(target) if target =~ /[^[:ascii:]]/
  end
end
