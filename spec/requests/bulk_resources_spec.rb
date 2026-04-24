require 'requests/login_helper_methods'

RSpec.describe 'BulkResourcesController' do
  let(:user) { create(:user) }
  let(:program_id) { program_with_units.id }
  let(:paths) do
    {
      root: upload_bulk_resources_uploader_path(program_id),
      bulk_delete: "/bulk_resources_uploader/upload/#{program_id}/bulk_delete"
    }
  end
  let(:resources_creator) { instance_double(BulkResourcesUploader::BulkResourcesCreator) }

  include_context 'when files were already uploaded to S3'

  before do
    allow(BulkResourcesUploader::BulkResourcesCreator).to receive(:new)
      .with(program_with_units).and_return(resources_creator)
  end

  describe '#index' do
    it 'redirects to unauthorized template when the user is not an editor' do
      log_in_user(user)
      get(bulk_resources_uploader_path)
      expect(response).to redirect_to('/403')
    end

    it 'redirects to Instructor Resources Bulk Upload view when the user is an editor' do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
      get(bulk_resources_uploader_path)
      expect(response.body).to include('Instructor Resources Bulk Upload')
    end

    it 'excludes archived programs from the list' do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
      create(:program, title: 'Archived Program', is_archived: true)
      get(bulk_resources_uploader_path)
      expect(response.body).not_to include('Archived Program')
    end

    it 'includes non-archived programs in the list' do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
      create(:program, title: 'Active Program', is_archived: false)
      get(bulk_resources_uploader_path)
      expect(response.body).to include('Active Program')
    end
  end

  describe '#select_program' do
    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
    end

    it 'redirects to upload view with valid program id' do
      get(select_program_bulk_resources_uploader_path(program_id:))
      expect(response).to redirect_to(paths[:root])
    end

    it 'sets error message when program is not found' do
      get(select_program_bulk_resources_uploader_path(program_id: 999_999))
      expect(flash[:alert]).to eq('Program not found.')
    end

    it 'redirects to root path when program is not found' do
      get(select_program_bulk_resources_uploader_path(program_id: 999_999))
      expect(response).to redirect_to('/')
    end
  end

  describe '#validate' do
    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
    end

    context 'when zip file is missing' do
      before do
        allow(resources_creator).to receive_messages(
          zip_exist_in_s3?: false,
          csv_exist_in_s3?: true
        )
        post("#{paths[:root]}/validate")
      end

      it 'returns missing files error message' do
        expect(response.parsed_body['error_message']).to eq('missing files')
      end

      it 'returns bad request status' do
        expect(response.parsed_body['status']).to eq('bad_request')
      end
    end

    context 'when csv file is missing' do
      before do
        allow(resources_creator).to receive_messages(
          zip_exist_in_s3?: true,
          csv_exist_in_s3?: false
        )
        post("#{paths[:root]}/validate")
      end

      it 'returns missing files error message' do
        expect(response.parsed_body['error_message']).to eq('missing files')
      end

      it 'returns bad request status' do
        expect(response.parsed_body['status']).to eq('bad_request')
      end
    end

    context 'when validating csv file name from BulkResourcesCreationTracker' do
      include_context 'when tracker is created'

      before do
        log_in_user(user)
        user.roles << Role.create(name: Role::RESOURCE_EDITOR)
        tracker.update(csv_file_name: custom_csv_file_name)
        allow(BulkResourcesUploader::BulkResourcesCreator).to receive(:new)
          .with(program_with_units).and_return(resources_creator)
        allow(resources_creator).to receive_messages(
          zip_exist_in_s3?: true,
          csv_exist_in_s3?: true,
          errors_report_exist_in_s3?: true,
          csv_errors_report: 'path/to/errors_report.csv'
        )
        allow(resources_creator).to receive_messages(
          validate_bulk_process: {
            errors_number: 0,
            errors_breakdown: {},
            warnings_number: 0,
            csv_file_name: custom_csv_file_name
          }
        )

        allow(resources_creator).to receive(:setup_tracker)
          .with(program_id, processing_files: true).and_return(tracker)
      end

      it 'uses the csv_file_name from BulkResourcesCreationTracker when available' do
        post("#{paths[:root]}/validate")
        expect(response.parsed_body['csv_file_name']).to eq(custom_csv_file_name)
      end

      it 'falls back to default name when csv_file_name is nil in tracker' do
        tracker.update(csv_file_name: nil)
        allow(resources_creator).to receive(:validate_bulk_process).and_return(
          errors_number: 0,
          errors_breakdown: {},
          warnings_number: 0,
          csv_file_name: 'erros_report.csv'
        )
        post("#{paths[:root]}/validate")
        expect(response.parsed_body['csv_file_name']).to eq('erros_report.csv')
      end

      it 'uses the tracker csv_file_name for download filename' do
        post("#{paths[:root]}/validate")
        expect(tracker.reload.csv_file_name).to eq(custom_csv_file_name)
      end
    end
  end

  describe '#upload_csv' do
    let(:csv_file_path) { "/bulk_resources_uploader/#{program_id}/#{program_id}_m3_resources.csv" }

    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
      allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
      allow(s3_bucket).to receive(:store_file_contents).and_return(true)
    end

    it 'returns file_uploaded key in response' do
      csv_content = "header1,header2\nvalue1,value2"
      post("#{paths[:root]}/upload_csv", params: { csv: { content: csv_content } })
      expect(response.parsed_body).to have_key('file_uploaded')
    end

    it 'stores empty content when csv content is empty' do
      post("#{paths[:root]}/upload_csv", params: { csv: { content: '' } })
      expect(s3_bucket).to have_received(:store_file_contents).with(any_args)
    end

    context 'when csv parameter is missing' do
      before do
        post("#{paths[:root]}/upload_csv")
      end

      it 'returns bad request status' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns error message in response' do
        expect(response.parsed_body['error'])
          .to start_with('param is missing or the value is empty: csv')
      end
    end
  end

  describe '#bulk_delete' do
    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
    end

    it 'removes resource from database' do
      resource = create(:resource, program_id:)
      post(paths[:bulk_delete])
      expect(Resource.exists?(resource.id)).to be false
    end
  end

  describe '#start_creation' do
    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
    end

    it 'increases BulkResourcesCreatorWorker jobs count' do
      expect do
        post("#{paths[:root]}/start_creation")
      end.to change(BulkResourcesCreatorWorker.jobs, :size).by(1)
    end

    it 'includes program_id in worker arguments' do
      post("#{paths[:root]}/start_creation")
      expect(BulkResourcesCreatorWorker.jobs.last['args'].first['program_id']).to eq(program_id)
    end
  end

  describe '#download_errors_report' do
    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
    end

    context 'when report does not exist' do
      before do
        allow(resources_creator).to receive(:errors_report_exist_in_s3?).and_return(false)
        get("#{paths[:root]}/download_errors_report")
      end

      it 'returns report not available message' do
        expect(response.parsed_body['error_message']).to eq('report not available')
      end

      it 'returns bad request status' do
        expect(response.parsed_body['status']).to eq('bad_request')
      end
    end

    context 'when report exists' do
      before do
        allow(resources_creator).to receive_messages(
          errors_report_exist_in_s3?: true,
          csv_errors_report: 'path/to/errors_report.csv'
        )
      end

      it 'returns success status' do
        get("#{paths[:root]}/download_errors_report")
        expect(response).to be_successful
      end
    end
  end

  describe '#files_s3_status' do
    let(:status_response) do
      {
        csv_last_modified: Time.current.to_s,
        zip_last_modified: Time.current.to_s
      }
    end

    before do
      log_in_user(user)
      user.roles << Role.create(name: Role::RESOURCE_EDITOR)
      allow(resources_creator).to receive(:files_status).and_return(status_response)
      get("#{paths[:root]}/files_s3_status")
    end

    it 'returns the csv_last_modified after checking the files status' do
      expect(response.parsed_body).to include('csv_last_modified')
    end

    it 'returns the zip_last_modified after checking the files status' do
      expect(response.parsed_body).to include('zip_last_modified')
    end
  end
end
