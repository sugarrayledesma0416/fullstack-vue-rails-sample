describe AccentBarEnhanced do
  describe "#characters" do
    before(:all) do
      @accent_bar_characters = YAML.load_file(Rails.root.join('config', 'accent_bar_characters.yml') )
    end

    it "should return Spanish accent characters when the argument is 'es'" do
      expect(AccentBarEnhanced.characters('es')).to eql @accent_bar_characters['es']
    end

    it "should return French accent characters when the argument is 'fr'" do
      expect(AccentBarEnhanced.characters('fr')).to eql @accent_bar_characters['fr']
    end

    it "should return Italian accent characters when the argument is 'it'" do
      expect(AccentBarEnhanced.characters('it')).to eql @accent_bar_characters['it']
    end

    it "should return German accent characters when the argument is 'de'" do
      expect(AccentBarEnhanced.characters('de')).to eql @accent_bar_characters['de']
    end

    it "should return a empty array when the argument is 'en'" do
      expect(AccentBarEnhanced.characters('en')).to eql []
    end

    it "should return a empty array when the argument is 'ru'" do
      expect(AccentBarEnhanced.characters('ru')).to eql []
    end

    it "should return nil when argument is 'ch'" do
      expect(AccentBarEnhanced.characters('ch')).to eql nil
    end

    it "should return nil when argument is blank" do
      expect(AccentBarEnhanced.characters('')).to eql nil
    end
  end
end
