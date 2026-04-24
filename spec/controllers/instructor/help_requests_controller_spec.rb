require 'instructor/help_requests_controller'
describe Instructor::HelpRequestsController do
  describe '#index' do
    let(:presenter) { double(InstructorHelpRequestsPresenter) }

    before do
      populate_instructor_program_and_focus
      allow(presenter).to receive(:populate).and_return(presenter) #populate returns self to allow method-chaining
      allow(InstructorHelpRequestsPresenter).to receive(:new).and_return(presenter)
    end

    def do_request
      get :index, params: { program_id: @program.id }
    end

    it_should_have_help
    it_behaves_like 'an action that requires a logged in instructor'
    it_behaves_like 'an action that assigns program and course, sections, and students from focus'
    it_behaves_like 'an action that assigns contextual help'

    it 'creates, populates and assigns an InstructorHelpRequests presenter, passing in sections and students from focus' do
      expect(InstructorHelpRequestsPresenter).to receive(:new).with(@sections, @students).and_return(presenter)
      expect(presenter).to receive(:populate).and_return(presenter)

      do_request

      expect(assigns(:presenter)).to eq(presenter)
    end
  end
end
