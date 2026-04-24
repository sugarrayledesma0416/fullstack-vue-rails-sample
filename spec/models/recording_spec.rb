describe Recording do
  let(:recording) { Recording.new }

  describe ".generate_file_prefix"  do

    it "creates a file prefix file path when it's called" do
      result = recording.generate_file_prefix
      expect(result).to match(/\/\w{3}\/\w{3}\/\w{3}\/\w{3}\//)
    end

    it "creates a file prefix file path that contains volume name" do
      result = recording.generate_file_prefix
      expect(result).to include "/#{Recording::VOLUME_NAME}/"
    end

    it 'creates a file prefix for student attempts if :student param is passed' do
      result = recording.generate_file_prefix(:student)
      expect(result).to include '/student_attempts/'
    end

    it 'creates a file prefix for instructor comments if :instructor param is passed' do
      result = recording.generate_file_prefix(:instructor)
      expect(result).to include '/instructor_comments/'
    end

    it 'creates a file prefix for student attempts if recording_type param is not passed' do
      result = recording.generate_file_prefix(nil)
      expect(result).to include '/student_attempts/'
    end

    it 'creates a file prefix including Date as part of the path' do
      Timecop.freeze(Time.local(2009, 7, 4)) do
        result = recording.generate_file_prefix
        expect(result).to include "/2009/07/04/"
      end
    end

    it "should create an generate_file_prefix file_path when it's called" do
      prefixes = []
      recording = Recording.new
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
      recording = Recording.create(:user => user, :recording_path => file_path)
      expect(recording.uuid).to eq('1ad4cd59-984b-4ac2-9363-fad03101522a')
    end
  end

end
