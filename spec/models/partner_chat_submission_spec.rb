describe PartnerChatSubmission, core: true do
  let(:activity) { build_stubbed(:activity) }
  let(:partner_submission_klass) { PartnerChatPartnerSubmission }
  let(:results) do
    instance_double(
      MaestroActivityEngine::ActivityContent::Results,
      first: { label: 'label' }
    )
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
      it 'label look up' do
        #TODO
      end
    end

  describe '#prepare_for_submission' do
    let(:partner_submission) do
      instance_double(partner_submission_klass)
    end
    let(:recording) { instance_double(PartnerChatRecording, id: 1010) }

    it 'udpates results' do
      expect(results).to receive(:set_response).with('label', '1010')

      submission = described_class.new(results, activity, {})

      allow(submission).to receive(:recording).and_return(recording)
      allow(partner_submission).to receive(:submit)
      allow(submission).to receive(:partner_submission).and_return(partner_submission)

      submission.prepare_for_submission('activity_complete', 'time_now')
    end

    it 'submits partner' do
      allow(results).to receive(:set_response)

      submission = described_class.new(results, activity, {})
      allow(submission).to receive(:recording).and_return(recording)

      expect(partner_submission).to receive(:submit).with({}, 'label', recording, 'activity_complete', 'time_now')
      allow(submission).to receive(:partner_submission).and_return(partner_submission)

      submission.prepare_for_submission('activity_complete', 'time_now')
    end
  end

  describe '#video_path' do
    it 'sets up' do
      #TODO
    end
  end

  describe '#recording' do
    let(:user) { create(:user) }
    let(:partner) { create(:user) }
    let(:partner_submission) do
      instance_double(partner_submission_klass, submission_required?: true)
    end
    let(:response) do
      {
        partner: partner_submission,
        partner_id: partner.id,
        recording_path: '/path/recording_path',
        token: 'token',
        user_id: user.id,
        user: user
      }
    end
    let(:submission) { described_class.new(results, activity, {}) }

    before do
      allow(partner_submission_klass).to receive(:new)
        .and_return(partner_submission)
      allow(results).to receive(:response).and_return(response)
    end

    it 'creates new partner chat recording ' do
      expect(submission.recording).not_to be_nil
    end

    it 'partner practice is true when submission is not required' do
      allow(partner_submission).to receive(:submission_required?).and_return(false)
      params = response.merge(activity: activity)
      expect(submission.recording.partner_practice).to be_truthy
    end
  end

  describe '#partner_submission' do
    let(:response) { { partner_section_id: 1, partner_id: 2 } }
    let(:submission) { described_class.new(results, activity, {}) }

    it 'create new partnet chat partner submission object' do
      allow(submission).to receive(:response).and_return(response)
      expect(PartnerChatPartnerSubmission).to receive(:new).with(response[:partner_id],
                                                                 response[:partner_section_id],
                                                                 activity)
      submission.partner_submission
    end
  end
end
