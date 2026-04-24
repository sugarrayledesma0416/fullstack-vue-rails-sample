RSpec.describe Instructor::CreatedActivity::ActivityTypePresenter do
  subject(:presenter) { described_class.new(view) }

  let(:view) { double('View') }

  describe '#activity_label' do
    context 'when no activity_params is provided' do
      it 'returns expected label' do
        expect(presenter.activity_label(:multiple_choice)).to eq('Multiple Choice')
      end
    end

    context 'when activity_params is provided' do
      it 'returns expected label' do
        expect(presenter.activity_label(:multiple_choice, choice_count: 2))
          .to eq('Multiple Choice (2 options)')
        expect(presenter.activity_label(:multiple_choice, choice_count: 3))
          .to eq('Multiple Choice (3 options)')
        expect(presenter.activity_label(:multiple_choice, choice_count: 4))
          .to eq('Multiple Choice (4 options)')
      end
    end
  end

  describe '#displayable_activity_types' do
    before { allow(view).to receive(:supersite_junior?).and_return(supersite_junior) }

    context 'when it is a supersite_junior' do
      let(:supersite_junior) { true }

      it 'filters out partner_chat activity type' do
        expect(presenter.displayable_activity_types.keys).not_to include(:partner_chat)
      end
    end

    context 'when it is not a supersite_junior' do
      let(:supersite_junior) { false }

      it 'returns all activity types' do
        expect(presenter.displayable_activity_types.keys).to include(:partner_chat)
      end
    end
  end

  describe '#sorted_displayable_activity_types' do
    before { allow(view).to receive(:supersite_junior?).and_return(false) }

    it 'returns sorted displayable activity types' do
      expected_types = %i[
        exam
        recording_v2
        composition
        drop_down
        external_link
        fill_in_the_blanks
        open_ended
        multiple_answer
        multiple_choice
        partner_chat
        audio_composition
        multiple_choice_same
        upload_file_activity
        external_video
        solo_video_recording
      ]

      expect(presenter.sorted_displayable_activity_types.to_h.keys).to eq(expected_types)
    end
  end

  describe '#formatted_activity_types' do
    before { allow(view).to receive(:supersite_junior?).and_return(false) }

    it 'returns all activity types including variants' do
      expected_types = [
        [:exam, {}],
        [:recording_v2, {}],
        [:composition, {}],
        [:drop_down, {}],
        [:external_link, {}],
        [:fill_in_the_blanks, {}],
        [:open_ended, {}],
        [:multiple_answer, {}],
        [:multiple_choice, { choice_count: 2 }],
        [:multiple_choice, { choice_count: 3 }],
        [:multiple_choice, { choice_count: 4 }],
        [:partner_chat, {}],
        [:audio_composition, {}],
        [:multiple_choice_same, {}],
        [:upload_file_activity, {}],
        [:external_video, {}],
        [:solo_video_recording, {}]
      ]

      expect(presenter.formatted_activity_types).to eq(expected_types)
    end
  end
end
