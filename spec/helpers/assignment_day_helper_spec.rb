describe AssignmentDayHelper do
  include AssignmentDayHelper

  describe "#style_for_bank" do
    context "with a background specified color" do
      before(:each) do
        @bank = double('Bank',:background_color => '#aabbcc')
        @style = style_for_bank(@bank)
      end

      it "should set the color style to the banks background color" do
        expect(@style).to match /#aabbcc/
      end

    end
  end
end
