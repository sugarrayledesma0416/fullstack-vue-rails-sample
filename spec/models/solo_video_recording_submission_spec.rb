describe SoloVideoRecordingSubmission, core: true do
  let(:activity) { build_stubbed(:activity) }
  let(:results) do
    instance_double(
      MaestroActivityEngine::ActivityContent::Results,
      first: { label: 'label' }
    )
  end

  let(:svr_content) { double('SoloVideoRecordingContent', label: 'svr_question_label') }
  let(:content_object) { double('ActivityContent', grading_method: 'instructor_graded',
                                activity_type: 'multi_type',
                                solo_video_recording_subactivity: svr_content) }
  let(:recording_path) { 'fake/solo/recording/path' }

  before do
    allow(activity).to receive(:activity_type).and_return('solo_video_recording')
  end

  describe '#response' do
    it 'looks up response from result based on the label' do
      allow(results).to receive(:response).with('label').and_return('response')
      submission = described_class.new(results, activity, {})
      allow(submission).to receive(:results).and_return(results)
      expect(submission.response).to eq('response')
    end
  end

    describe '#label' do
      it 'returns the label used to lookup the response' do
        submission = described_class.new(results, activity, {})
        expect(submission.label).to eq 'label'
      end

      it 'returns the label used to lookup the response' do
        allow(activity).to receive(:activity_type).and_return('multi_type')
        allow(activity).to receive(:content_object).and_return(content_object)
        submission = described_class.new(results, activity, {})
        expect(submission.label).to eq 'svr_question_label'
      end
    end

  describe '#prepare_for_submission' do
    let(:recording) { instance_double(SoloVideoRecording, id: 1010) }

    it 'updates results' do
      expect(results).to receive(:set_response).with('label', '1010')
      submission = described_class.new(results, activity, {})
      allow(submission).to receive(:recording).and_return(recording)
      submission.prepare_for_submission('activity_complete', 'time_now')
    end
  end

  describe '#recording' do
    let(:user) { create(:user) }
    let(:response) do
      {
        recording_path: recording_path,
        user_id: user.id,
        user: user
      }
    end
    let(:submission) { described_class.new(results, activity, {}) }

    before do
      allow(results).to receive(:response).and_return(response)
    end

    it 'creates new solo video recording ' do
      expect(submission.recording).not_to be_nil
    end
  end

  describe '#video_path' do
    let(:user) { create(:user) }
    let(:partner) { create(:user) }
    let(:response) do
      {
        recording_path: recording_path,
        user_id: user.id,
        user: user
      }
    end
    let(:submission) { described_class.new(results, activity, {}) }

    before do
      allow(results).to receive(:response).and_return(response)
    end

    it 'returns the correct video recording path' do
      expect(submission.video_path).to eq recording_path
    end
  end
end
