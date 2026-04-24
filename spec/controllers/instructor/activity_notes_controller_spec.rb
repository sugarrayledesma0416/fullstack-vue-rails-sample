describe Instructor::ActivityNotesController do
  let(:activity) { build_stubbed(:activity) }
  let(:body_text) { 'Lorem ipsum' }
  let(:cms_revision_id) { 1234567 }
  let(:note) { build_stubbed(:activity_note) }

  describe '#index' do
    before do
      populate_instructor_program_and_focus
      allow(@instructor.activity_notes).to receive(:by_activity).and_return([note])
    end

    def do_request(params = {})
      default_params = { program_id: @program.id, activity_id: activity.id }
      get :index, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    it 'finds current_users notes for the specified activity id' do
      expect(@instructor.activity_notes).to receive(:by_activity).with(activity.id.to_s).and_return([note])
      do_request
    end

    it 'renders a json array of the notes retrieved' do
      do_request
      expect(response.body).to eq([note].to_json)
    end
  end

  describe '#destroy' do
    let(:note) { build_stubbed(:activity_note) }

    before do
      populate_instructor_program_and_focus
      allow(@instructor.activity_notes).to receive(:find).and_return(note)
      allow(note).to receive(:destroy)
    end

    def do_request(params = {})
      default_params = {
        activity_id: activity.id,
        id: note.id,
        program_id: @program.id
      }
      post :destroy, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    it 'finds the note with the specified id' do
      do_request
      expect(@instructor.activity_notes).to have_received(:find).with(note.id.to_s)
    end

    it 'destroys the note' do
      do_request
      expect(note).to have_received(:destroy)
    end
  end
end
