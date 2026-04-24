class Language
  def self.all
    language_hash.sort { |a, b| a[1] <=> b[1] }
  end

  def self.names_from_codes(code_list)
    return '' unless code_list

    code_list.split(',').map { |code| language_hash[code] }.sort.join(', ')
  end

  def self.language_hash
    {
      'fr' => 'French',
      'it' => 'Italian',
      'es' => 'Spanish',
      'de' => 'German',
      'en' => 'English',
      'zh' => 'Chinese',
      'ru' => 'Russian'
    }
  end
end
