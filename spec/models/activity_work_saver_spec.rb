describe ActivityWorkSaver, :core => true do
   let(:activity) { double('Activity', :id => 55, :content_object => '<content>some_content</content>', :cms_revision_id => 1, :composition? => false) }
   let(:results) { double('MaestroActivityEngine::ActivityContent::Results') }
   let(:attempt_track) { double('AttemptTrack') }
   let(:recording_saver){ double('RecordingSaver') }
   let(:attempt) { double(Attempt, :section_id => 56,
                                   :user => build_stubbed(:user),
                                   :activity_id => 55,
                                   :submitted_values? => false,
                                   :results => results,
                                   :cms_revision_id => 222) }

  let(:activity_params) { { :id => '55',
                            :section_id => 1,
                            :question_01 => 'right answer',
                            :start_time => 15.minutes.ago.utc } }
  let(:request) do
    double('request', env: {'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'})
  end

  before do
    allow(attempt).to receive(:validate_responses).and_return(results)
    allow(attempt).to receive(:write_results)
    allow(attempt).to receive(:results).and_return(results)
    allow(attempt).to receive(:attempt_track).and_return(attempt_track)
    allow(RecordingSaver).to receive(:new).and_return(recording_saver)
    allow(recording_saver).to receive(:save_recordings)
  end


  describe '#save' do
    it "validates activity's responses for passed question params" do
      expect(attempt)
        .to receive(:validate_responses)
        .with(activity, activity_params, request.env, :unsubmitted)
        .and_return(results)
      ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
    end

    it 'creates recordings records' do
      expect(RecordingSaver).to receive(:new).with(activity, attempt.user, results)
      expect(recording_saver).to receive(:save_recordings)
      ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
    end

    it "writes results to attempt's responses xml" do
      expect(attempt).to receive(:write_results).with(results, false, :unsubmitted, activity_params[:start_time].to_i, Time.now.utc.to_i)
      ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
    end

    it "generates results to be assigned to the activity view" do
      expect(attempt).to receive(:results).and_return(results)
      ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
    end

    it "generates attempt track to be assigned to the activity view" do
      expect(attempt).to receive(:attempt_track)
      ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
    end

    it 'sets result attribute' do
      saver = ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
      expect(saver.results).to eq(results)
    end

    it 'sets attempt_track attribute' do
      saver = ActivityWorkSaver.new(activity, attempt, activity_params, request.env).save
      expect(saver.attempt_track).to eq(attempt_track)
    end
  end
end
