describe Attemptable do
  class AttemptableObj
    include Attemptable
  end

  describe '#classwork' do
    before do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
      @attemptable = AttemptableObj.new
    end

    it 'returns a classwork object' do
      @classwork = double(Classwork)
      expect(Classwork).to receive(:new).with(@user, @section.id).and_return(@classwork)
      expect(@attemptable.classwork_for(@user, @section)).to eq(@classwork)
    end
  end

  describe '#attempt_for' do
    before do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
      @attempt = build_stubbed(:attempt)
      @attemptable = AttemptableObj.new
    end

    it 'returns the attempt for the user in the section' do
      expect(Attempt).to receive(:find_or_new).with(@user, @attemptable, @section.id).and_return(@attempt)
      expect(@attemptable.attempt_for(@user, @section)).to eq(@attempt)
    end
  end

  describe '#attempt_track_for' do
    before do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
      @attempt = build_stubbed(:attempt)
      @attempt_track = double(AttemptTrack)
      @attemptable = AttemptableObj.new
    end

    it 'returns the attempt tracker for the user' do
      expect(@attemptable).to receive(:attempt_for).with(@user, @section).and_return(@attempt)
      expect(@attempt).to receive(:attempt_track).and_return(@attempt_track)
      expect(@attemptable.attempt_track_for(@user, @section)).to eq(@attempt_track)
    end
  end
end
