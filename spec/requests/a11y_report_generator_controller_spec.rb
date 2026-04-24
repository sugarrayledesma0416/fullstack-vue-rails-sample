require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe A11yReportGeneratorController do
  let!(:program) { create(:program) }
  let(:include_details) { 'true' }
  let(:user) { create(:user) }

  describe 'GET/index' do
    include_examples 'require logged in user'

    def do_request
      get index_a11y_report_generator_path
    end

    context 'as a logged in user' do
      before do
        log_in_user(user)
      end

      it "renders the program index if I'm a resource_editor" do
        user.roles << Role.create(name: Role::RESOURCE_EDITOR)
        do_request
        expect(response).to render_template(:index)
      end

      it "shows the list of programs if I'm a resource_editor" do
        user.roles << Role.create(name: Role::RESOURCE_EDITOR)
        do_request
        results = Capybara.string(response.body)
        expect(results).to have_selector(:id, 'program_id')
      end

      it "redirects me if I'm not a resource_editor" do
        do_request
        expect(response).to redirect_to('/403')
      end
    end
  end

  describe 'GET /report' do
    include_examples 'require logged in user'

    def do_request
      get report_a11y_report_generator_path(program_id: program.id)
    end

    context 'as a logged in user' do
      before do
        log_in_user(user)
      end

      describe 'as a resource_editor' do
        let(:report_tool) do
          instance_double(
            A11yReportGenerator,
            simplified_report_url: 'http://simplified.report/download',
            detailed_report_url: 'http://detailed.report/download',
            simplified_report_last_modified: 'some date',
            detailed_report_last_modified: 'some other date'
          )
        end

        before do
          user.roles << Role.create(name: Role::RESOURCE_EDITOR)
          allow(A11yReportGenerator).to receive(:new).and_return(report_tool)
        end

        it 'renders the report view' do
          do_request
          expect(response).to render_template(:report)
        end

        it 'instantiates A11yReportGenerator class with the correct program' do
          do_request
          expect(A11yReportGenerator).to have_received(:new).with(program.id)
        end
      end

      it "redirects me if I'm not a resource_editor" do
        do_request
        expect(response).to redirect_to('/403')
      end
    end
  end

  describe 'GET /generate_reports' do
    include_examples 'require logged in user'

    def do_request
      get generate_report_a11y_report_generator_path(
        program_id: program.id, include_details: include_details
      )
    end

    context 'as a logged in user' do
      before do
        log_in_user(user)
      end

      describe 'as a resource_editor' do
        before do
          user.roles << Role.create(name: Role::RESOURCE_EDITOR)
          allow(A11yReportGeneratorWorker).to receive(:perform_async)
            .with(program.id, include_details)
        end

        it 'renders the generate_new_report view' do
          do_request
          expect(response).to render_template(:generate_new_report)
        end

        it 'Calls the background worker to generate the report' do
          do_request
          expect(A11yReportGeneratorWorker).to have_received(:perform_async)
            .with(program.id, include_details)
        end
      end

      it "redirects me if I'm not a resource editor" do
        do_request
        expect(response).to redirect_to('/403')
      end
    end
  end
end
