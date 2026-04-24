describe GroupChatSubmission, core: true do
  let(:activity) { build_stubbed(:activity) }
  let(:results) do
    instance_double(
      MaestroActivityEngine::ActivityContent::Results,
      first: { label: expected_label },
      set_response: nil
    )
  end
  let(:expected_label) { 'group_chat_label' }
  let(:user) { create(:user) }
  let(:partners) { [create(:user), create(:user), create(:user)] }

  let(:group_chat_content) do
    instance_double(
      MaestroActivityEngine::ActivityContent::GroupChatContent,
      label: 'group_chat_question_label'
    )
  end
  let(:recording_path) { 'fake/group_chat/recording/path' }
  let(:submission) { described_class.new(results, activity, {}) }

  before do
    allow(activity).to receive(:activity_type).and_return('group_chat')
  end

  describe '#response' do
    it 'looks up response from result based on the label' do
      expected_response = 'group_chat_response'
      allow(results).to receive(:response).with(expected_label).and_return(expected_response)
      submission = described_class.new(results, activity, {})
      allow(submission).to receive(:results).and_return(results)
      expect(submission.response).to eq(expected_response)
    end
  end

  describe '#label' do
    it 'returns the label used to lookup the response' do
      submission = described_class.new(results, activity, {})
      expect(submission.label).to eq expected_label
    end
  end

  describe '#prepare_for_submission' do
    let(:section) { create(:section) }
    let(:response) do
      {
        partner_ids: partners.map(&:id),
        recording_path: recording_path,
        token: 'token',
        partner_section_ids: partners.each_with_object({}) do |partner, hash|
          hash[partner.id] = section.id
        end,
        user_id: user.id
      }
    end
    let(:submission) { described_class.new(results, activity, {}) }
    let(:recording) { instance_double(GroupChatRecording, id: Random.rand(1..30)) }
    let(:group_chat_partner_submissions) do
      [
        instance_double(GroupChatPartnerSubmission, submit: nil),
        instance_double(GroupChatPartnerSubmission, submit: nil),
        instance_double(GroupChatPartnerSubmission, submit: nil)
      ]
    end
    let(:activity_status) { 'activity_complete' }
    let(:submitted_time) { Time.current }

    before do
      allow(submission).to receive(:recording).and_return(recording)
      allow(results).to receive(:response).with(expected_label).and_return(response)
      allow(GroupChatPartnerSubmission).to receive(:new)
      partners.each_with_index do |partner, index|
        allow(GroupChatPartnerSubmission).to receive(:new)
          .with(partner.id, section.id, activity)
          .and_return(group_chat_partner_submissions[index])
      end
    end

    it 'updates the response' do
      submission.prepare_for_submission(activity_status, submitted_time)
      expect(results).to have_received(:set_response).with(expected_label, recording.id.to_s)
    end

    it 'makes the submission for the other partners' do
      submission.prepare_for_submission(activity_status, submitted_time)
      group_chat_partner_submissions.each do |group_chat_partner_submission|
        expect(group_chat_partner_submission).to have_received(:submit)
          .with({}, expected_label, recording, activity_status, submitted_time)
      end
    end
  end

  describe '#recording if partners has not completed the activity' do
    let(:section) { create(:section) }
    let!(:attempt1) { create(:attempt_opened, activity: activity, section: section, user: partners[0]) }
    let!(:attempt2) { create(:attempt_opened, activity: activity, section: section, user: partners[1]) }
    let!(:attempt3) { create(:attempt_opened, activity: activity, section: section, user: partners[2]) }
    let(:partner_submission) do
      instance_double(GroupChatPartnerSubmission, submission_required?: true)
    end
    let(:response) do
      {
        partner_ids: partners.map(&:id),
        partner_section_ids: partners.each_with_object({}) do |partner, hash|
          hash[partner.id] = section.id
        end,
        recording_path: recording_path,
        token: 'token',
        user_id: user.id
      }
    end

    before do
      allow(GroupChatPartnerSubmission).to receive(:new)
        .and_return(partner_submission)
      allow(results).to receive(:response).and_return(response)
    end

    it 'creates new group chat recording ' do
      expect(submission.recording).not_to be_nil
    end

    it 'returns practising_partners array as empty' do
      expect(submission.recording.practicing_users).to be_empty
    end
  end

  describe '#recording if some partners has completed the activity' do
    let(:section) { create(:section) }
    let!(:attempt1) { create(:attempt_opened, activity: activity, section: section, user: partners[0]) }
    let!(:attempt2) { create(:attempt_opened, activity: activity, section: section, user: partners[1]) }
    let!(:attempt3) { create(:attempt_completed, activity: activity, section: section, user: partners[2]) }
    let(:partner_submission) do
      instance_double(GroupChatPartnerSubmission, submission_required?: true)
    end
    let(:response) do
      {
        partner_ids: partners.map(&:id),
        partner_section_ids: partners.each_with_object({}) do |partner, hash|
          hash[partner.id] = section.id
        end,
        recording_path: recording_path,
        token: 'token',
        user_id: user.id
      }
    end

    before do
      allow(GroupChatPartnerSubmission).to receive(:new)
        .and_return(partner_submission)
      allow(results).to receive(:response).and_return(response)
    end

    it 'returns practising_partners array as non empty' do
      expect(submission.recording.practicing_users).not_to be_empty
    end

    it 'returns partners id which has completed the activity' do
      expect(submission.recording.practicing_users).to include(partners[2].id)
    end
  end

  describe '#video_path' do
    let(:section) { create(:section) }
    let!(:attempt1) { create(:attempt_opened, activity: activity, section: section, user: partners[0]) }
    let!(:attempt2) { create(:attempt_opened, activity: activity, section: section, user: partners[1]) }
    let!(:attempt3) { create(:attempt_opened, activity: activity, section: section, user: partners[2]) }
    let(:response) do
      {
        partner_ids: partners.map(&:id),
        recording_path: recording_path,
        partner_section_ids: partners.each_with_object({}) do |partner, hash|
          hash[partner.id] = section.id
        end,
        token: 'token',
        user_id: user.id
      }
    end

    before do
      allow(results).to receive(:response).and_return(response)
    end

    it 'returns the correct video recording path' do
      expect(submission.video_path).to eq recording_path
    end
  end
end
