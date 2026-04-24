describe PartnerChatPartnerSubmission, core: true do
  let(:partner) { create(:student) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity) }

  before do
    allow(User).to receive(:find).and_return(partner)
    allow(Section).to receive(:find).and_return(section)
  end

  describe '#submission_required?' do
    it 'returns false when partner is an instructor' do
      instructor = build_stubbed(:instructor)
      allow(User).to receive(:find).and_return(instructor)

      pc_partner_submission = described_class.new(instructor.id, section.id, activity)

      expect(pc_partner_submission).not_to be_submission_required
    end

    context 'when partner is not an instructor' do
      it 'returns false when attempt is completed' do
        create(
          :attempt_completed,
          activity_id: activity.id,
          section_id: section.id,
          user_id: partner.id
        )

        pc_partner_submission = described_class.new(partner.id, section.id, activity)

        expect(pc_partner_submission).not_to be_submission_required
      end

      it 'returns true when attempt is not completed' do
        create(
          :attempt_opened,
          activity_id: activity.id,
          section_id: section.id,
          user_id: partner.id
        )

        pc_partner_submission = described_class.new(partner.id, section.id, activity)

        expect(pc_partner_submission).to be_submission_required
      end

      it 'returns false for info_gap_partner_chat_v2 activity even when attempt is not completed' do
        activity_v2 = create(:activity, activity_type: 'info_gap_partner_chat_v2')
        create(
          :attempt_opened,
          activity_id: activity_v2.id,
          section_id: section.id,
          user_id: partner.id
        )

        pc_partner_submission = described_class.new(partner.id, section.id, activity_v2)

        expect(pc_partner_submission).not_to be_submission_required
      end
    end
  end

  describe '#submit' do
    let(:recording) { build_stubbed(:partner_chat_recording) }

    let(:results) do
      instance_double(
        MaestroActivityEngine::ActivityContent::Results,
        instructor_graded_score_pending?: true,
        set_response: true
      )
    end

    let(:gradebook_submission) { instance_double(Gradebook::Submission, submit: true) }

    before do
      # rubocop:disable RSpec/AnyInstance
      # This is the only way to avoid reading from / writing to Submissions.
      allow_any_instance_of(AttemptStats).to receive(:validate_responses).and_return(results)
      allow_any_instance_of(Attempt).to receive(:write_results)
      # rubocop:enable RSpec/AnyInstance
      allow(Gradebook::Submission).to receive(:new).and_return(gradebook_submission)
      allow(results).to receive(:each).and_yield(response: recording)
    end

    it 'does not create a gradebook submission if partner is an instructor' do
      instructor = build_stubbed(:instructor)
      allow(User).to receive(:find).and_return(instructor)

      pc_partner_submission = described_class.new(instructor.id, section.id, activity)
      pc_partner_submission.submit({}, '', recording, '', '')

      expect(Gradebook::Submission).not_to have_received(:new)
    end

    context 'when partner is not an instructor' do
      it 'does not create a gradebook submission if partner has a completed attempt' do
        create(
          :attempt_completed,
          activity_id: activity.id,
          section_id: section.id,
          user_id: partner.id
        )

        pc_partner_submission = described_class.new(partner.id, section.id, activity)
        pc_partner_submission.submit({}, '', recording, '', '')

        expect(Gradebook::Submission).not_to have_received(:new)
      end

      it 'creates a gradebook submission when partner has an incomplete attempt' do
        create(
          :attempt_opened,
          activity_id: activity.id,
          section_id: section.id,
          user_id: partner.id
        )

        pc_partner_submission = described_class.new(partner.id, section.id, activity)
        pc_partner_submission.submit({}, '', recording, '', '')

        expect(Gradebook::Submission).to have_received(:new)
          .with(partner, section, activity)
      end
    end
  end
end
