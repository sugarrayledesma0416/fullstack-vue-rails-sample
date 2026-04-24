# The name can be changed back to AccentBar
# once the accent bar old implementation is removed completely.

class AccentBarEnhanced
  def self.characters(language)
    @accent_characters ||= YAML.load_file(Rails.root.join('config', 'accent_bar_characters.yml'))
    @accent_characters[language]
  end
end
