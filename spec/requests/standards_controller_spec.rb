RSpec.describe StandardsController do
  include BasicAuthLogin
  describe 'GET /program_id/standards_mapping_activities_template' do
    include_context 'with basic auth'
    let(:program) { create(:program) }

    context 'with a valid login' do
      it 'calls #activities_mapping_csv' do
        controller_instance = described_class.new
        allow(controller_instance).to receive(:activities_mapping_csv).and_return('foo')
        allow(described_class).to receive(:new).and_return(controller_instance)

        get "/#{program.id}/standards_mapping_activities_template", as: :json, headers: login
        expect(response.body).to eq({ csv: 'foo' }.to_json)
      end
    end

    context 'with an invalid login' do
      it 'returns unauthorized' do
        get "/#{program.id}/standards_mapping_activities_template", as: :json, headers: bad_login
        expect(response).to be_unauthorized
      end
    end
  end

  describe 'GET /program_id/standards_mapping_assessments_template' do
    include_context 'with basic auth'
    let(:program) { create(:program) }

    context 'with a valid login' do
      it 'calls #standards_mapping_assessments_template' do
        controller_instance = described_class.new
        allow(controller_instance).to receive(:assessments_mapping_csv).and_return('boo')
        allow(described_class).to receive(:new).and_return(controller_instance)

        get "/#{program.id}/standards_mapping_assessments_template", as: :json, headers: login
        expect(response.body).to eq({ csv: 'boo' }.to_json)
      end
    end

    context 'with an invalid login' do
      it 'returns unauthorized' do
        get "/#{program.id}/standards_mapping_assessments_template", as: :json, headers: bad_login
        expect(response).to be_unauthorized
      end
    end
  end

  describe 'GET /program_id/standards_mapping_toc_csv' do
    include_context 'with basic auth'
    let(:program) { create(:program) }

    context 'with a valid login' do
      it 'calls #standards_mapping_toc_csv' do
        allow(StandardsMapping::EReaderCsvGenerator)
          .to receive(:generate_toc_csv).with(program.id).and_return('goober')

        get "/#{program.id}/standards_mapping_toc_csv", as: :json, headers: login
        expect(response.body).to eq({ csv: 'goober' }.to_json)
      end
    end

    context 'with an invalid login' do
      it 'returns unauthorized' do
        get "/#{program.id}/standards_mapping_assessments_template", as: :json, headers: bad_login
        expect(response).to be_unauthorized
      end
    end
  end

  describe 'GET /standards_mapping_ereader_csv' do
    include_context 'with basic auth'

    context 'with a valid login' do
      it 'calls #standards_mapping_ereader_template' do
        allow(StandardsMapping::EReaderCsvGenerator)
          .to receive(:generate_csv_string).and_return('crocs are valid shoes')

        get '/standards_mapping_ereader_template', as: :json, headers: login
        expect(response.body).to eq({ csv: 'crocs are valid shoes' }.to_json)
      end
    end

    context 'with an invalid login' do
      it 'returns unauthorized' do
        get '/standards_mapping_ereader_template', as: :json, headers: bad_login
        expect(response).to be_unauthorized
      end
    end
  end
end
