require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe InstructorResourcesExportController do
  let!(:program) { create(:program) }
  let(:user) { create(:user) }

  describe 'GET /index' do
    include_examples 'require logged in user'

    def do_request
      get index_instructor_resources_export_path
    end

    context 'when the user is logged in' do
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

  describe 'GET /export' do
    include_examples 'require logged in user'

    def do_request
      get export_instructor_resources_export_path(program_id: program.id)
    end

    context 'when the user is logged in' do
      before do
        log_in_user(user)
      end

      describe 'when the user is resource_editor' do
        let(:exporter) do
          instance_double(
            InstructorResourcesExport,
            { zip_exist_in_s3?: zip_present,
              signed_url: expected_download_link,
              last_modified:,
              formatted_file_size: file_size }
          )
        end
        let(:expected_download_link) { 'https://my_exported_file.zip' }
        let(:last_modified) { 'some date' }
        let(:file_size) { 'file_size' }
        let(:zip_present) { true }

        before do
          user.roles << Role.create(name: Role::RESOURCE_EDITOR)
          allow(InstructorResourcesExport).to receive(:new).and_return(exporter)
          allow(exporter).to receive(:set_file_path_to_zip)
        end

        it 'renders the export view' do
          do_request
          expect(response).to render_template(:export)
        end

        it 'instantiates resources class with the correct program' do
          do_request
          expect(InstructorResourcesExport).to have_received(:new).with(program)
          expect(exporter).to have_received(:set_file_path_to_zip)
        end
      end

      it "redirects me if I'm not a resource_editor" do
        do_request
        expect(response).to redirect_to('/403')
      end
    end
  end

  describe 'GET /generate_link' do
    include_examples 'require logged in user'

    def do_request
      get generate_link_instructor_resources_export_path(program_id: program.id)
    end

    context 'when the user is logged in' do
      before do
        log_in_user(user)
      end

      describe 'when the user is resource_editor' do
        before do
          user.roles << Role.create(name: Role::RESOURCE_EDITOR)
          allow(InstructorResourcesExportWorker).to receive(:perform_async).with(program.id)
        end

        it 'renders the generate_new_link view' do
          do_request
          expect(response).to render_template(:generate_new_link)
        end

        it 'Calls the background worker to export the zip' do
          do_request
          expect(InstructorResourcesExportWorker).to have_received(:perform_async).with(program.id)
        end
      end

      it "redirects me if I'm not a resource editor" do
        do_request
        expect(response).to redirect_to('/403')
      end
    end
  end

  describe 'GET /export_csv' do
    include_examples 'require logged in user'

    def do_request
      get export_csv_instructor_resources_export_path(program_id: program.id)
    end

    context 'when the user is logged in' do
      before do
        log_in_user(user)
      end

      describe 'as a resource_editor' do
        let(:exporter) do
          instance_double(
            InstructorResourcesExport,
            {
              csv_exists_in_s3?: csv_exists,
              signed_url: csv_download_link,
              export_resources_to_csv: true,
              upload_csv_file: true
            }
          )
        end
        let(:csv_download_link) { 'https://my_exported_file.csv' }
        let(:csv_exists) { true }

        before do
          user.roles << Role.create(name: Role::RESOURCE_EDITOR)
          allow(InstructorResourcesExport).to receive(:new).and_return(exporter)
          allow(InstructorResourcesExportWorker).to receive(:perform_async)
          allow(exporter).to receive(:set_file_path_to_csv)
        end

        it 'redirects to the CSV download link if the file exists' do
          do_request
          expect(exporter).to have_received(:set_file_path_to_csv)
          expect(response).to redirect_to(csv_download_link)
        end

        context 'when the CSV file does not exist after retries' do
          let(:csv_exists) { false }

          it 'flashes an error message and redirects to the index' do
            do_request
            expect(flash[:error]).to eq(
              'The requested CSV file could not be generated. Please try again later.'
            )
            expect(response).to redirect_to(index_instructor_resources_export_path)
          end
        end

        it 'calls the background worker to generate the CSV' do
          do_request
          expect(InstructorResourcesExportWorker)
            .to have_received(:perform_async).with(program.id, 'csv')
        end
      end

      it "redirects me if I'm not a resource_editor" do
        do_request
        expect(response).to redirect_to('/403')
      end
    end
  end
end
