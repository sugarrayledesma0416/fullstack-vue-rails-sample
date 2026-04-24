describe StandardAlignmentsController do
  include BasicAuthLogin
  include_context 'with basic auth'
  before do
    add_auth_header(request)
  end

  describe '#update' do
    before do
      allow(StandardAlignmentsUpdateWorker).to receive(:perform_async)
    end

    it 'responds with OK, sends job to worker' do
      put(:update, format: :json, params: { program_id: 1234 })
      expect(response).to have_http_status(:ok)
      expect(StandardAlignmentsUpdateWorker)
        .to have_received(:perform_async).with({ 'program_id' => '1234' })
    end

    it 'responds with OK, sends job to worker with optional param' do
      put(:update, format: :json, params: {
            program_id: 1234,
            import_type: 'import-new-alignments'
          })
      expect(response).to have_http_status(:ok)
      expect(StandardAlignmentsUpdateWorker)
        .to have_received(:perform_async).with({ 'program_id' => '1234',
                                                 'import_type' => 'import-new-alignments' })
    end

    it 'returns an error when required param is missing a value' do
      expect { put(:update, format: :json, params: { program_id: '' }) }.to raise_error(
        ActionController::ParameterMissing,
        /param is missing or the value is empty: program_id/
      )
    end

    it 'returns conflict when an update is already in progress' do
      allow(controller).to receive(:conflicting_process_running?).with(StandardAlignmentsUpdateWorker).and_return(true)

      put(:update, format: :json, params: { program_id: 1234 })

      expect(response).to have_http_status(:conflict)
      expect(StandardAlignmentsUpdateWorker).not_to have_received(:perform_async)

      parsed = JSON.parse(response.body)
      expect(parsed['message']).to match(/already in progress/i)
    end
  end
end
