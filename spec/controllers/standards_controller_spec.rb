describe StandardsController do
  include BasicAuthLogin
  include_context 'with basic auth'

  before do
    add_auth_header(request)
  end

  describe '#show' do
    context 'when the provided standard guid exists' do
      let(:guid) { 'ABCDEF123-4567-8901-2345-67890ABCDEF1' }

      it 'responds with a 200' do
        create(:standard, vendor_guid: guid)
        get(:show, params: { id: guid }, format: :js)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the provided standard guid does not exist' do
      let(:guid) { 'ABCDEF123-4567-8901-2345-67890ABCDEF1' }

      it 'responds with a 404' do
        get(:show, params: { id: guid }, format: :js)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '#update_all' do
    before do
      standards_call = Rails.root.join('spec/fixtures/json/standards.json').read
      stub_request(:get, 'https://api.abconnect.certicaconnect.com/rest/v4.1/standards')
        .to_return(status: 200, body: standards_call)
      allow(StandardsUpdateWorker).to receive(:perform_async)
    end

    it 'responds with OK, sends job to worker' do
      put(:update_all)
      expect(response).to have_http_status(:ok)
      expect(StandardsUpdateWorker).to have_received(:perform_async)
    end
  end

  describe '#standards_mapping_activities_template' do
    let!(:program) { create(:program) }

    context 'with a valid program id param' do
      it 'calls activities_mapping_csv and returns a csv string' do
        allow(controller).to receive(:activities_mapping_csv).and_return('foo,bar')
        get(:standards_mapping_activities_template, params: { program_id: program.id }, format: :json)
        expect(response.body).to eq({ csv: 'foo,bar' }.to_json)
      end
    end

    context 'with an invalid program id param' do
      it 'returns an error message' do
        bad_id = Program.last.id + 1
        get(:standards_mapping_activities_template, params: { program_id: bad_id }, format: :json)
        msg = "The program ID #{bad_id} is not a valid program id."
        expect(response.parsed_body['error_message']).to eq(msg)
      end
    end
  end

  describe '#standards_mapping_assessments_template' do
    let!(:program) { create(:program) }

    context 'with a valid program id param' do
      it 'calls assessments_mapping_csv and returns a csv string' do
        allow(controller).to receive(:assessments_mapping_csv).and_return('foo,bar')
        get(:standards_mapping_assessments_template, params: { program_id: program.id }, format: :json)
        expect(response.body).to eq({ csv: 'foo,bar' }.to_json)
      end
    end

    context 'with an invalid program id param' do
      it 'returns an error message' do
        bad_id = Program.last.id + 1
        get(:standards_mapping_assessments_template, params: { program_id: bad_id }, format: :json)
        msg = "The program ID #{bad_id} is not a valid program id."
        expect(response.parsed_body['error_message']).to eq(msg)
      end
    end
  end

  describe '#standards_mapping_ereader_template' do
    it 'returns the csv template' do
      allow(StandardsMapping::EReaderCsvGenerator)
        .to receive(:generate_csv_string).and_return('foo,bar,jar')

      get(:standards_mapping_ereader_template, format: :json)
      expect(response.parsed_body.symbolize_keys).to eq({ csv: 'foo,bar,jar' })
    end
  end

  describe '#standards_mapping_toc_csv' do
    let!(:program) { create(:program) }

    context 'with a valid program id param' do
      it 'returns the toc as a csv' do
        allow(StandardsMapping::EReaderCsvGenerator)
          .to receive(:generate_toc_csv).and_return('foo,bar,very,far')

        get(:standards_mapping_toc_csv, params: { program_id: program.id }, format: :json)
        expect(response.parsed_body.symbolize_keys).to eq({ csv: 'foo,bar,very,far' })
      end
    end

    context 'with an invalid program id param' do
      it 'returns an error message' do
        bad_id = Program.last.id + 1
        get(:standards_mapping_toc_csv, params: { program_id: bad_id }, format: :json)
        msg = "The program ID #{bad_id} is not a valid program id."
        expect(response.parsed_body['error_message']).to eq(msg)
      end
    end
  end

  describe '#standard_assets_template' do
    let!(:program) { create(:program) }

    context 'with a valid program id param' do
      it 'calls assets_mapping_csv and returns a csv string' do
        allow(controller).to receive(:assets_mapping_csv).and_return('foo,bar')
        get(:standard_assets_template, params: { program_id: program.id, asset_type: 'Activity' }, format: :json)
        expect(response.body).to eq({ csv: 'foo,bar' }.to_json)
      end
    end

    context 'with an invalid program id param' do
      it 'returns an error message' do
        bad_id = Program.last.id + 1
        get(:standard_assets_template, params: { program_id: bad_id, asset_type: 'Activity' }, format: :json)
        msg = "The program ID #{bad_id} is not a valid program id."
        expect(response.parsed_body['error_message']).to eq(msg)
      end
    end
  end
end
