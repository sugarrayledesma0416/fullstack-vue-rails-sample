describe RecordingSaver do
  describe '#save_recordings' do
    let(:results) { MaestroActivityEngine::ActivityContent::Results.new }
    let(:activity) { create(:activity) }
    let(:user) { create(:user) }

    it 'does not create a record when recording already exists' do
      existing_path = '/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_1'
      results.add({ :label => 'question_1', :response => existing_path })
      recording = create(:recording, :recording_path => existing_path, :user => user)
      RecordingSaver.new(activity, user, results).save_recordings

      expect(Recording.where(recording_path: existing_path).size).to eq(1)
    end

    context "when the activity isn't either vchat or recording_v2" do
      it "does not create any records" do
        activity.activity_type = 'composition'
        recording_saver = RecordingSaver.new(activity, user, results)

        expect { recording_saver.save_recordings }.to change(Recording, :count).by(0)
      end
    end

    context 'when activity is recording_v2' do
      let(:responses) { [ {:label => 'question_1', :response => '/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_1' },
                        {:label => 'question_2', :response => '/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_2' } ] }

      before do
        activity.activity_type = 'recording_v2'
        responses.each { |response| results.add(response) }
      end

      it 'creates a recording for each question label for the activity' do
        recording_saver = RecordingSaver.new(activity, user, results)
        expect { recording_saver.save_recordings }.to change(Recording, :count).by(2)
      end
    end

    context 'when activity is vchat' do
      let(:responses){ [ { :label   => 'question_1',
                          :response => '{"gender": "male", "turn_1": "/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_1", "turn_2": "/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_2"}' }] }
      let(:content_object){ double('ContentObject', :turn_paths => ["/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_1", "/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_2"]) }

      before do
        activity.activity_type = 'virtual_chat'
        allow(activity).to receive(:content_object).and_return(content_object)
        responses.each { |response| results.add(response) }
      end

      it 'creates a recording for each turn present in the activity' do
        recording_saver = RecordingSaver.new(activity, user, results)
        expect { recording_saver.save_recordings }.to change(Recording, :count).by(2)
        #Recording.all.should =~ ["/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_1", "/path/to/131196d5-e8fc-4d46-a930-dafe8b485f16_2"]
      end
    end
  end
end
