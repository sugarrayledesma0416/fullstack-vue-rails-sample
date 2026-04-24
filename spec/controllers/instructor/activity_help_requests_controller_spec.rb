describe Instructor::ActivityHelpRequestsController do
  let(:section) { build_stubbed(:section) }
  let(:focus) { double(Focus, sections: [section]) }
  let(:activity) { build_stubbed(:activity) }
  let(:help_request) { build_stubbed(:help_request) }
  let(:student) { build_stubbed(:student) }
  let(:student_ids_param) { { 0 => student.id.to_s } }

  describe '#index' do
    let(:scope) { double('scope', include_users: [help_request]) }

    before do
      populate_instructor_program_and_focus
      allow(controller).to receive(:current_focus).and_return(focus)
      allow(HelpRequest).to receive(:instructor_respondable_by_section_user_activity_and_question).and_return(scope)
    end

    def do_request(params = {})
      default_params = { program_id: @program.id, activity_id: activity.id }
      get :index, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    context 'when no question_id param is specified' do
      it 'finds help requests for the specified activity and user, and renders them as JSON' do
        expect(HelpRequest).to receive(:instructor_respondable_by_section_user_activity_and_question).with([section], [student.id.to_s], activity.id.to_s, nil).and_return(scope)
        do_request(student_ids: student_ids_param)

        expect(response.body).to eq([help_request].to_json(HelpRequest::ACTIVITY_JSON_OPTIONS))
      end
    end

    context 'when a question_id param is specified' do
      it 'finds help requests for the specified activity and users, and question_label, and renders them as JSON' do
        question_id = 'question_123'
        expect(HelpRequest).to receive(:instructor_respondable_by_section_user_activity_and_question).with([section], [student.id.to_s], activity.id.to_s, question_id).and_return(scope)
        do_request(student_ids: student_ids_param, question_id: question_id)

        expect(response.body).to eq([help_request].to_json(HelpRequest::ACTIVITY_JSON_OPTIONS))
      end
    end
  end
end
