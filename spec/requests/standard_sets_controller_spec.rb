RSpec.describe StandardSetsController do
  let(:basic_auth) { ActionController::HttpAuthentication::Basic }
  let!(:standard_set_1) { create(:standard_set) }
  let!(:standard_set_2) { create(:standard_set) }

  before do
    stub_const('HTTP_AUTHENTICATIONS', { 'maestro' => 'secret' })
  end

  def login
    user = HTTP_AUTHENTICATIONS.keys.first
    password = HTTP_AUTHENTICATIONS[user]
    {
      HTTP_AUTHORIZATION: basic_auth.encode_credentials(user, password)
    }
  end

  describe 'GET :index' do
    context 'with valid basic auth' do
      before do
        get '/standard_sets.json', headers: login
      end

      it 'Returns the standard sets as json' do
        expected = [
          { id: standard_set_1.id, name: standard_set_1.name },
          { id: standard_set_2.id, name: standard_set_2.name }
        ].to_json
        expect(response.body).to eq(expected)
      end
    end

    context 'without valid auth' do
      before do
        get '/standard_sets.json'
      end

      it 'returns 401 unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '#standards_by_display_name' do
    before do
      get '/standard_sets/grouped_by_display_name.json', headers: login
    end

    it 'returns the standards sets grouped by display name' do
      expected = {
        standard_set_1.display_name => [{
          display_name: standard_set_1.display_name,
          vendor_guid: standard_set_1.vendor_guid,
          id: nil
        }],
        standard_set_2.display_name => [{
          display_name: standard_set_2.display_name,
          vendor_guid: standard_set_2.vendor_guid,
          id: nil
        }]
      }.to_json
      expect(response.body).to eq(expected)
    end
  end

  describe 'POST /standard_sets/standards_by_sets' do
    context 'with valid basic auth' do
      # child standards of standard_set_1
      let!(:standard_1_a) do
        create(:standard, standard_set: standard_set_1)
      end
      let!(:standard_1_b) do
        create(:standard, standard_set: standard_set_1)
      end

      # child standards of standard_set_2
      let!(:standard_2_a) do
        create(:standard, standard_set: standard_set_2)
      end
      let!(:standard_2_b) do
        create(:standard, standard_set: standard_set_2)
      end

      before do
        # standard set that params[:set_ids] will not include
        standard_set_3 = create(:standard_set)

        # child standards of standard_set_3
        create(:standard, standard_set: standard_set_3)
        post(
          '/standard_sets/standards_by_sets.json',
          params: { set_ids: [standard_set_1.id, standard_set_2.id] },
          headers: login
        )
      end

      it 'Returns the requested standard sets as json' do
        expected = [
          {
            'standard_vendor_guid' => standard_1_a.vendor_guid,
            'standard_set_name' => standard_set_1.name,
            'standard_number' => standard_1_a.number,
            'standard_label' => standard_1_a.label,
            'standard_description' => standard_1_a.description
          },
          {
            'standard_vendor_guid' => standard_1_b.vendor_guid,
            'standard_set_name' => standard_set_1.name,
            'standard_number' => standard_1_b.number,
            'standard_label' => standard_1_b.label,
            'standard_description' => standard_1_b.description
          },
          {
            'standard_vendor_guid' => standard_2_a.vendor_guid,
            'standard_set_name' => standard_set_2.name,
            'standard_number' => standard_2_a.number,
            'standard_label' => standard_2_a.label,
            'standard_description' => standard_2_a.description
          },
          {
            'standard_vendor_guid' => standard_2_b.vendor_guid,
            'standard_set_name' => standard_set_2.name,
            'standard_number' => standard_2_b.number,
            'standard_label' => standard_2_b.label,
            'standard_description' => standard_2_b.description
          }
        ]
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'without valid auth' do
      before do
        post '/standard_sets/standards_by_sets.json'
      end

      it 'returns 401 unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
