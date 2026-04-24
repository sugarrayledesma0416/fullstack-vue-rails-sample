describe AttemptTrackHelper do
  include AttemptTrackHelper

  context "when formatting the Attempt tracking string" do
    it "should show how many are used and how many remain" do
      track = AttemptTrack.new(1, 5)
      resp = format_used_and_remaining(track)
      expect(resp).to eql('1 used / 4 remaining')
    end

    it "should show unlimited attempts when max is unlimited" do
      track = AttemptTrack.new(1, -1)
      resp = format_used_and_remaining(track)
      expect(resp).to eql('1 used / unlimited remaining')
    end

    it "should should the number used and Activity Complete when finished" do
      track = AttemptTrack.new(3, 5)
      track.complete = true
      resp = format_used_and_remaining(track)
      expect(resp).to eql('3 used / Activity complete')
    end

    it "should Activity Complete when the activity is view only" do
      track = AttemptTrack.new(0, 0)
      resp = format_used_and_remaining(track)
      expect(resp).to eql('Activity viewed')
    end
  end
end
