describe AttemptTrack, :core => true do

  describe "#final?" do
    it "when on first attempt should be false " do
      track = AttemptTrack.new(1, -1)
      expect(track.final?).to be_falsey
    end

    it "should not report the final attempt if the user has unlimited attempts" do
      track = AttemptTrack.new(999, -1)
      expect(track.final?).to be_falsey
    end

    it "when on last attempt should be true" do
      track = AttemptTrack.new(4, 5)
      expect(track.final?).to be_truthy
    end
  end

  describe "#used" do
    it "should be equal to the attempt_number passed in" do
      [0, 1, 2, 3, 4, 5].each do |number|
        track = AttemptTrack.new(number, 'unlimited')
        expect(track.used).to eql(number)
      end
    end
  end

  describe "#number" do
    it "should be 1 more than the attempt_number passed in" do
      [0, 1, 2, 3, 4, 5].each do |number|
        track = AttemptTrack.new(number, 'unlimited')
        expect(track.number).to eql(number+1)
      end
    end
  end

  describe "#remaining" do
    it "when max is unlimited should be 'unlimited'" do
      track = AttemptTrack.new(1, -1)
      expect(track.remaining).to eql('unlimited')
    end

    it "should be max - number" do
      max = 10
      [0, 1, 2, 3, 4, 5].each do |number|
        track = AttemptTrack.new(number, max)
        expect(track.remaining).to eql((max-number).to_s)
      end
    end

    it "when on last attempt should be 1 " do
      track = AttemptTrack.new(4, 5)
      expect(track.remaining).to eql('1')
    end
  end

  describe "#view_only" do
    it "when max is 0 should be true" do
      track = AttemptTrack.new(0, 0)
      expect(track.view_only?).to be_truthy
    end
  end

  describe "#submitted?" do
    context "when not submitted" do
      it "should be false" do
        track = AttemptTrack.new(0, 3)
        expect(track.submitted?).to be_falsey
      end
    end

    context "when submitted" do
      it "should be true" do
        track = AttemptTrack.new(1, 3)
        expect(track.submitted?).to be_truthy
      end
    end
  end

end
