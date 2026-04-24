describe Xapi::StateController, if: DynamoConfig.use_local?,
                                use_local_dynamodb: true do
  let(:user) { create(:student) }
  let(:username) { 'username' }
  let(:user_password) { 'password' }
  let(:user_token) do
    XapiUserToken.new(
      attempt_id: attempt.id,
      state_modifiable: true,
      user_id: user.id
    )
  end
  let(:agent) { { objectType: 'Agent', mbox: user_token.mbox, name: 'Anonymous' }.to_json }
  let(:payload) { 'payload' }
  let(:milliseconds_spent) { 666 }
  let(:page_location) { '#/lang/en/pag/2f6e65a01fe52899e7bc9ec3300d452c||en' }
  let(:learning_module_id) { 'https://netexlearning.com/487203' }
  let(:request_env) { {} }
  let(:state_id_prefix) { "#{Rails.env}_#{Socket.gethostname}_" }
  let(:state_id) { "#{state_id_prefix}#{attempt.id}" }

  def basic_auth_headers
    auth_string = ActionController::HttpAuthentication::Basic.encode_credentials(
      username, user_password
    )
    { 'HTTP_AUTHORIZATION' => auth_string }
  end

  describe 'GET /xapi/activities/state' do
    let(:default_params) do
      {
        stateId: 'courseData',
        activityId: learning_module_id,
        agent: agent,
        app: 'wcloud',
        attempts: 1
      }
    end

    def do_request
      get '/xapi/activities/state', params: default_params, headers: basic_auth_headers
    end

    context 'when the user is not authenticated,' do
      let(:attempt) { create(:attempt, user: user) }

      before do
        allow(Xapi::BasicAuthCredential).to receive(:valid_credentials?)
          .with(username, user_password).and_return(false)
      end

      it 'returns a 401 error' do
        do_request
        expect(Xapi::BasicAuthCredential).to have_received(:valid_credentials?)
          .with(username, user_password)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user is authenticated,' do
      before do
        allow(Xapi::BasicAuthCredential).to receive(:valid_credentials?)
          .with(username, user_password).and_return(true)
      end

      context 'when no state exists,' do
        let(:attempt) { build_stubbed(:attempt, user: user) }

        it 'returns a 500 error' do
          # We don't really have a 500 error. We just check if an error is raised
          # This error is later converted to a 500 error page.
          expect { do_request }.to raise_error(ArgumentError)
        end
      end

      context 'when an attempt exist but no activity state exists,' do
        let(:attempt) { create(:attempt, user: user) }

        it 'returns a 404 error' do
          do_request
          expect(response).to have_http_status(:not_found)
          expect(response.body).to eq(
            Xapi::StateController::STATE_NOT_FOUND_ERROR_MSG
          )
        end
      end

      context 'when an activity state exists,' do
        let(:attempt) { create(:attempt, user: user) }

        before do
          Xapi::ActivityState.new(
            activity_id: attempt.activity_id,
            id: state_id,
            milliseconds_spent: milliseconds_spent,
            page_location: page_location,
            payload: payload,
            section_id: attempt.section_id,
            user_id: attempt.user_id
          ).save!
        end

        it 'returns a json of the activity state' do
          do_request

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json).to eq(
            'suspend' => payload,
            'location' => page_location,
            'totalTime' => milliseconds_spent
          )
        end
      end
    end
  end

  describe 'PUT /xapi/activities/state' do
    let(:new_payload) { 'some new payload' }
    let(:new_page_location) { 'new location' }
    let(:new_milliseconds_spent) { milliseconds_spent + 60_000 }

    let(:default_params) do
      {
        stateId: 'courseData',
        activityId: learning_module_id,
        agent: agent,
        app: 'wcloud',
        attempts: 1,
        state: {
          suspend: new_payload,
          location: new_page_location,
          totalTime: new_milliseconds_spent
        }
      }
    end

    def do_request
      put '/xapi/activities/state', params: default_params, headers: basic_auth_headers
    end

    context 'when the user is not authenticated,' do
      let(:attempt) { create(:attempt, user: user) }

      before do
        allow(Xapi::BasicAuthCredential).to receive(:valid_credentials?)
          .with(username, user_password).and_return(false)
      end

      it 'returns a 401 error' do
        do_request
        expect(Xapi::BasicAuthCredential).to have_received(:valid_credentials?)
          .with(username, user_password)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user is authenticated,' do
      before do
        allow(Xapi::BasicAuthCredential).to receive(:valid_credentials?)
          .with(username, user_password).and_return(true)
      end

      context 'when no attempt exists,' do
        let(:attempt) { build_stubbed(:attempt, user: user) }

        it 'returns a 500 error' do
          # We don't really have a 500 error. We just check if an error is raised
          # This error is later converted to a 500 error page.
          expect { do_request }.to raise_error(ArgumentError)
        end
      end

      context 'when an attempt exists but no activity state exists,' do
        let(:attempt) { create(:attempt, user: user) }

        it 'returns no content and creates a new page state record' do
          do_request
          expect(response).to have_http_status(:no_content)

          record = Xapi::ActivityState.find(id: state_id)
          expect(record).to have_attributes(
            activity_id: attempt.activity_id,
            milliseconds_spent: new_milliseconds_spent,
            page_location: new_page_location,
            payload: new_payload,
            section_id: attempt.section_id,
            user_id: attempt.user_id
          )
        end
      end

      context 'when an attempt and an activity state exist,' do
        let(:attempt) { create(:attempt, user: user) }

        before do
          Xapi::ActivityState.new(
            id: state_id,
            user_id: user.id,
            section_id: attempt.section_id,
            activity_id: attempt.activity_id,
            page_location: page_location,
            payload: payload,
            milliseconds_spent: milliseconds_spent
          ).save!
        end

        it 'returns no content and updates the existing page state record' do
          do_request
          expect(response).to have_http_status(:no_content)

          record = Xapi::ActivityState.find(id: state_id)

          expect(record).to have_attributes(
            activity_id: attempt.activity_id,
            milliseconds_spent: new_milliseconds_spent,
            page_location: new_page_location,
            payload: new_payload,
            section_id: attempt.section_id,
            user_id: attempt.user_id
          )
        end
      end
    end
  end
end
