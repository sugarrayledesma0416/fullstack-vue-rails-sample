RSpec.describe Instructor::CreatedActivity::NewActivityLinkPresenter do
  include ActionView::TestCase::Behavior
  subject(:presenter) { described_class.new(view, instructor_presenter) }

  let(:instructor_presenter) { double('InstructorPresenter') }

  describe '#formatted_activity_types' do
    before { allow(view).to receive(:supersite_junior?).and_return(supersite_junior)  }

    context 'when it is a supersite_junior' do
      let(:supersite_junior) { true }

      it 'returns corresponding activity types including variants' do
        expected_types = [
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
          [:audio_composition, {}],
          [:multiple_choice_same, {}],
          [:upload_file_activity, {}],
          [:external_video, {}],
          [:solo_video_recording, {}]
        ]

        expect(presenter.formatted_activity_types).to eq(expected_types)
      end
    end

    context 'when it is not a supersite_junior' do
      let(:supersite_junior) { false }

      it 'returns corresponding activity types including variants' do
        expected_types = [
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
end
