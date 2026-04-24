describe DictionaryEntriesController do
  include_context 'when the program contains the activities with supported activity_types'
  let(:program_id) { '123' }
  let(:cms_activity_ids) { %w[1 2 3] }
  let(:related_cms_activities_ids) { activities.pluck(:cms_activity_id).map(&:to_s) }

  describe '#generate_report' do
    it 'shows an error if the program does not exist on m3' do
      allow(DictionaryEntriesReportWorker).to receive(:perform_async)
        .with(program_id, cms_activity_ids)
      get :generate_report, params: { program_id:, cms_activity_ids: }

      expect(response.parsed_body).to eq(
        'error_message' => "Program #{program_id} is not present in M3."
      )
    end

    it 'enqueues the worker and returns an acepted status' do
      allow(DictionaryEntriesReportWorker).to receive(:perform_async)
        .with(program.id.to_s, related_cms_activities_ids)
      get :generate_report, params: {
        program_id: program.id,
        cms_activity_ids: related_cms_activities_ids
      }

      expect(response).to have_http_status(:accepted)
    end

    it 'enqueues the worker and returns a success message' do
      allow(DictionaryEntriesReportWorker).to receive(:perform_async)
        .with(program.id.to_s, related_cms_activities_ids)
      get :generate_report, params: {
        program_id: program.id,
        cms_activity_ids: related_cms_activities_ids
      }

      expect(response.parsed_body).to eq(
        'message' => 'The CSV generation process has started. This may take several minutes.'
      )
    end
  end

  describe '#download_csv' do
    let(:reporter) { DictionaryEntriesExport::DictionaryEntriesReport.new(program_id:, cms_activity_ids:) }

    before do
      allow(DictionaryEntriesExport::DictionaryEntriesReport).to receive(:new)
        .with(program_id:, cms_activity_ids:).and_return(reporter)
    end

    context 'when the CSV exists in S3' do
      before do
        allow(reporter).to receive(:csv_exists_in_s3?).and_return(true)
        allow(reporter).to receive(:signed_url)
          .and_return('https://example.com/signed_url')
      end

      it 'returns the signed URL' do
        get :download_csv, params: { program_id:, cms_activity_ids: }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          'found_errors'=>false,
          'signed_url' => 'https://example.com/signed_url'
        )
      end
    end

    context 'when the CSV does not exist in S3' do
      before do
        allow(reporter).to receive(:csv_exists_in_s3?).and_return(false)
      end

      it 'returns not_found status' do
        get :download_csv, params: { program_id:, cms_activity_ids: }

        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        get :download_csv, params: { program_id:, cms_activity_ids: }

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq(
          'error_message' => 'The file is not available yet.'
        )
      end
    end
  end
end
