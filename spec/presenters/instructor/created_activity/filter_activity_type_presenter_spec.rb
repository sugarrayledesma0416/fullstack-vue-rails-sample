RSpec.describe Instructor::CreatedActivity::FilterActivityTypePresenter do
  subject(:presenter) { described_class.new(view) }

  let(:view) { double('View') }

  describe '#formatted_activity_types' do
    before { allow(view).to receive(:supersite_junior?).and_return(supersite_junior) }

    context 'when it is a supersite_junior' do
      let(:supersite_junior) { true }

      it 'returns corresponding activity types' do
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
          multiple_choice_same
          upload_file_activity
          external_video
          solo_video_recording
        ]

        expect(presenter.formatted_activity_types.keys).to eq(expected_types)
      end
    end

    context 'when it is not a supersite_junior' do
      let(:supersite_junior) { false }

      it 'returns corresponding activity types' do
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
          multiple_choice_same
          upload_file_activity
          external_video
          solo_video_recording
        ]

        expect(presenter.formatted_activity_types.keys).to eq(expected_types)
      end
    end
  end
end
