#  encoding: utf-8

describe String do
  describe "#remove_accents" do
    it "removes accents from spanish characters" do
      result = "ÁÉÍÓÚáéíóúÑñÜü".remove_accents
      expect(result).to eq("AEIOUaeiouNnUu")
    end

    it "removes accents from french characters" do
      result = "ÉéÀÈÙàèùÂÊÎÔÛâêîôûÄÏÜäïüÇç".remove_accents
      expect(result).to eq("EeAEUaeuAEIOUaeiouAIUaiuCc")
    end

    it "removes accents from italian characters" do
      result = "ÁÉÍÓÚáéíóúÀÈÌÒÙàèìòù".remove_accents
      expect(result).to eq("AEIOUaeiouAEIOUaeiou")
    end

    it "removes accents from german characters" do
      result = "ÄÖÜäöüß".remove_accents
      expect(result).to eq("AOUaouss")
    end

    it "does not remove number sign from a given string" do
      result = "tool#läterälus".remove_accents
      expect(result).to eq("tool#lateralus")
    end
  end

  describe "#shorten" do
    before(:each) do
      @terminator = "&hellip;".html_decode
    end

    context "on a long string" do
      context "with no parameters" do
        it "should shorten the string to 20 characters and add an ellipsis" do
          expect(("c"*30).shorten).to eql( ("c"*20) + @terminator)
        end
      end

      context "when provided a valid length" do
        it "should shorten the string to the specified number of characters and add an ellipsis" do
          expect(("c"*10).shorten(4)).to eql( ("c"*4) + @terminator)
        end

        it "should return the string shortened to the integer value of a non-integer length" do
          expect(("c"*10).shorten(1.2)).to eql("c" + @terminator)
        end

        it "should return the string shortened to the integer value of a numerical string length" do
          expect(("c"*5).shorten('2')).to eql( ("c"*2) + @terminator)
        end
      end

      context "when provided an invalid length" do
        it "should return the string unmodified for a negative length" do
          expect(("c"*5).shorten(-1)).to eql("c"*5)
        end

        it "should return the string unmodified for a zero length" do
          expect(("c"*5).shorten(0)).to eql("c"*5)
        end

        it "should return the string unmodified for a non-numerical length" do
          expect(("c"*5).shorten('a')).to eql("c"*5)
        end
      end
    end

    context "on a short string" do
      it "should return the string unmodified" do
        expect(("c"*5).shorten).to eql("c"*5)
      end
    end

    context "on a string with entitized characters" do
      it "should shorten to the specified length after translating the entities" do
        expect("123&ntilde;56789A".shorten(6)).to eql("123" + "&ntilde;".html_decode + "56" + @terminator)
      end
    end

    context "on a string with html tags" do
      it "should shorten to the specified length ignoring the tags", test_debt: true do
        pending 'warren'
        expect(("This is a <b>long</b> string").shorten(12)).to eql( ("This is a <b>lo</b>") + @terminator)
      end
    end
  end

  describe "#combine_overlap" do
    it "should concatenate strings with no overlap, separated by a dash" do
      expect('ab'.combine_overlap('cd')).to eq('ab - cd')
    end

    it "should return the common starting chars, then the different chars separated by a dash" do
      expect('ab'.combine_overlap('ac')).to eql 'ab-c'
      expect('Lesson 1'.combine_overlap('Lesson 2')).to eq('Lesson 1-2')
    end

    it "should not combine common chars from the end of the string" do
      expect('ab'.combine_overlap('cb')).to eq('ab - cb')
    end

  end

  describe '#to_utf8' do
    it 'converts windows-1252 encoded chars to utf-8' do
      test_string = "Ñ".encode("Windows-1252")
      expect(test_string.to_utf8).to eq(test_string.encode("UTF-8", "Windows-1252", undef: :replace))
    end
  end
end
