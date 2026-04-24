describe VideoRecording do
  describe ".generate_file_prefix" do

    let(:recording) { VideoRecording.new }

    it "returns a string containing a uuid broken into chunks of 3 characters" do
      result = recording.generate_file_prefix
      expect(result).to match(/\/\w{3}\/\w{3}\/\w{3}\/\w{3}\//)
    end

    it "returns a string that contains volume name directory" do
      result = recording.generate_file_prefix
      expect(result).to include "/#{Recording::VOLUME_NAME}/"
    end

    it 'returns a string including an instructor_activity directory' do
      result = recording.generate_file_prefix
      expect(result).to include '/instructor_activity/'
    end

    it 'returns a string including directories for year, month, and day' do
      Timecop.freeze(Time.local(2009, 7, 4)) do
        result = recording.generate_file_prefix
        expect(result).to include "/2009/07/04/"
      end
    end

    it "returns a unique string each time it is called" do
      prefixes = []
      recording = VideoRecording.new
      0.upto(2).each do
        prefixes << recording.generate_file_prefix
      end
      expect(prefixes.uniq.size).to eq(3)
    end
  end

  describe 'when creating' do
    it 'sets uuid' do
      user = create(:student)
      file_path = '/recording/1ad4cd59-984b-4ac2-9363-fad03101522a_10'
      recording = VideoRecording.create(:user => user, :recording_path => file_path)
      expect(recording.uuid).to eq('1ad4cd59-984b-4ac2-9363-fad03101522a')
    end
  end

end
