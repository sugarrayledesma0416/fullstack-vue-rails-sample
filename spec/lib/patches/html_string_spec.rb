#  encoding: utf-8

describe HTMLString do
  describe "#shorten" do
    before(:each) do
      @trail_character = "&hellip;".html_decode
    end

    context "on a long string" do
      context "with no parameters" do
        it "should shorten the string to 20 characters and add an ellipsis" do
          expect((HTMLString.new("c"*30)).shorten).to eql( ("c"*20) + @trail_character)
        end
      end

      context "when provided a valid length" do
        it "should shorten the string to the specified number of characters and add an ellipsis" do
          expect((HTMLString.new("c"*10)).shorten(4)).to eql( ("c"*4) + @trail_character)
        end

        it "should return the string shortened to the integer value of a non-integer length" do
          expect((HTMLString.new("c"*10)).shorten(1.2)).to eql("c" + @trail_character)
        end

        it "should return the string shortened to the integer value of a numerical string length" do
          expect((HTMLString.new("c"*5)).shorten('2')).to eql( ("c"*2) + @trail_character)
        end
      end

      context "when provided an invalid length" do
        it "should return the string unmodified for a negative length" do
          expect((HTMLString.new("c"*5)).shorten(-1)).to eql("c"*5)
        end

        it "should return the string unmodified for a zero length" do
          expect((HTMLString.new("c"*5)).shorten(0)).to eql("c"*5)
        end

        it "should return the string unmodified for a non-numerical length" do
          expect((HTMLString.new("c"*5)).shorten('a')).to eql("c"*5)
        end
      end
    end

    context "on a short string" do
      it "should return the string unmodified" do
        expect((HTMLString.new("c"*5)).shorten).to eql("c"*5)
      end
    end

    context "on a string with entitized characters" do
      it "should shorten to the specified length after translating the entities" do
        expect((HTMLString.new("123&ntilde;56789A")).shorten(6)).to eql("123" + "&ntilde;".html_decode + "56" + @trail_character)
      end
    end

    context "when a trail character is specified as blank" do
      it "returns the string with no trailing character " do
        expect((HTMLString.new("c"*25)).shorten(20, '')).to eql("c"*20)
      end
    end

    context "on a string with html tags" do
      it "should shorten to the specified length ignoring the tags" do
        expect((HTMLString.new("This is a <b>long</b> string")).shorten(12)).to eql( ("This is a <b>lo</b>") + @trail_character)
        expect((HTMLString.new("This <i>is</i> a <b>long</b> string")).shorten(12)).to eql( ("This <i>is</i> a <b>lo</b>") + @trail_character)
        expect((HTMLString.new("This is a <i><b>long</b> string </i>")).shorten(12)).to eql( ("This is a <i><b>lo</b></i>") + @trail_character)
        expect((HTMLString.new("This is text <!-- This is a comment -->")).shorten(12)).to eql( ("This is text") + @trail_character)
      end

      it "should shorten to the specified length ignoring the tags but maintiains the tag attributes in the output", test_debt: true do
        pending "jayan"
        expect((HTMLString.new("This is a <span class='cool'>long</span> string")).shorten(12)).to eql( ("This is a <span class='cool'>lo</span>") + @trail_character)
      end
    end
  end
end
