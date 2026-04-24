RSpec.describe Standards::AssetsController do
  include BasicAuthLogin
  include_context 'with basic auth'
  let(:create_params) do
    {
      standard_asset: {
        vendor_guid: SecureRandom.uuid,
        reference_id: 123,
        reference_type: 'Activity',
        m3_publish_status: true
      }
    }
  end
  let(:guid_2) { SecureRandom.uuid }
  let(:guid_3) { SecureRandom.uuid }
  let(:assessment) { create(:activity) }
  let(:create_with_assessment_item_params) do
    {
      standard_asset: {
        vendor_guid: guid_2,
        reference_type: 'AssessmentItem',
        m3_publish_status: true,
        assessment_item_attributes: {
          guid: guid_2,
          assessment_id: assessment.id,
          points_possible: 10
        }
      }
    }
  end
  let(:concept) { create(:concept) }
  let(:basic_auth) { ActionController::HttpAuthentication::Basic }

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

  def bad_login
    {
      HTTP_AUTHORIZATION: basic_auth.encode_credentials('foo', 'bar')
    }
  end

  describe 'POST /create' do
    before do
      post '/standards/assets', params: create_params, as: :json, headers: login
    end

    it 'responds with a created status' do
      expect(response).to have_http_status(:created)
    end

    it 'saves the asset record' do
      expect(StandardAsset.where(reference_id: 123)).to exist
    end

    context 'with valid nested assessment_item attributes' do
      let(:create_params) do
        {
          standard_asset: {
            vendor_guid: guid_2,
            reference_type: 'AssessmentItem',
            m3_publish_status: true,
            assessment_item_attributes: {
              guid: guid_2,
              assessment_id: assessment.cms_activity_id,
              points_possible: 10
            }
          }
        }
      end

      it 'responds with a created status' do
        expect(response).to have_http_status(:created)
      end

      it 'saves the asset and assessment item record' do
        standard_asset = StandardAsset.where(
          vendor_guid: guid_2,
          reference_type: 'AssessmentItem'
        ).first

        expect(standard_asset.assessment_item).to be_present
      end
    end

    context 'with valid nested ereader_item attributes' do
      let(:create_params) do
        {
          standard_asset: {
            vendor_guid: guid_3,
            reference_type: 'EReaderItem',
            m3_publish_status: true,
            ereader_item_attributes: {
              guid: guid_3,
              concept_id: concept.id,
              title: 'Identity',
              page_section: 'Exploring Your Identity',
              descriptor: 'Determine the meaning of multiple words and phrases',
              page_number: 2
            }
          }
        }
      end

      it 'responds with a created status' do
        expect(response).to have_http_status(:created)
      end

      it 'saves the asset and assessment item record' do
        standard_asset = StandardAsset.where(
          vendor_guid: guid_3,
          reference_type: 'EReaderItem'
        ).first
        expect(standard_asset.ereader_item).to be_present
      end
    end

    context 'with a duplicate vendor guid' do
      it 'raises a validation error' do
        existing_standard_asset = create(:standard_asset)
        create_params[:standard_asset][:vendor_guid] = existing_standard_asset.vendor_guid
        expected =
          {
            error: {
              attempted_attrs: {
                vendor_guid: existing_standard_asset.vendor_guid,
                reference_id: 123,
                reference_type: 'Activity',
                m3_publish_status: true,
                date_alignments_modified_utc: nil,
                additional_attrs: nil
              },
              msg: 'Vendor guid has already been used'
            }
          }.to_json

        post '/standards/assets', params: create_params, as: :json, headers: login
        expect(response.body).to eq(expected)
      end
    end

    context 'with bad login creds' do
      before do
        post '/standards/assets', params: create_params, as: :json, headers: bad_login
      end

      it 'returns a 401' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /update' do
    let (:standard_asset) { create(:standard_asset) }
    
    context 'with valid params' do
      let(:update_params) do
        {
          standard_asset: {
            vendor_guid: standard_asset.vendor_guid,
            reference_id: 789,
            reference_type: 'Activity',
            m3_publish_status: true
          }
        }
      end

      before do
        put "/standards/assets/#{standard_asset.vendor_guid}", params: update_params, as: :json, headers: login
      end

      it 'responds with an ok status' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the asset record' do
        standard_asset.reload
        expect(StandardAsset.find(standard_asset.id).reference_id).to eq(789)
      end
    end

    context 'when the asset does not exist' do
      let(:update_params) do
        {
          standard_asset: {
            vendor_guid: SecureRandom.uuid,
            reference_id: 789,
            reference_type: 'Activity',
            m3_publish_status: true
          }
        }
      end

      before do
        put "/standards/assets/#{SecureRandom.uuid}", params: update_params, as: :json, headers: login
      end

      it 'responds with a not found status' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when validation fails' do
      let(:update_params) do
        {
          standard_asset: {
            vendor_guid: nil,
            reference_id: 370,
            reference_type: 'Activity',
            m3_publish_status: true
          }
        }
      end

      before do
        put "/standards/assets/#{standard_asset.vendor_guid}", params: update_params, as: :json, headers: login
      end

      it 'responds with an unprocessable entity status' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the validation errors' do
        json_response = JSON.parse(response.body)
        expect(json_response['error']['msg']).to eq('Vendor guid is required')
      end
    end

    context 'with bad login creds' do
      let(:update_params) do
        {
          standard_asset: {
            vendor_guid: standard_asset.vendor_guid,
            reference_id: 789
          }
        }
      end

      before do
        put "/standards/assets/#{standard_asset.vendor_guid}", params: update_params, as: :json, headers: bad_login
      end

      it 'returns a 401' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
