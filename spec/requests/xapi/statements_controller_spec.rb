describe Xapi::StatementsController do
  TIMESTAMP_FORMAT = '%FT%T%:z'.freeze

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
  let(:actor) { { mbox: user_token.mbox, objectType: 'Agent' } }
  let(:statement) do
    {
      id: SecureRandom.uuid,
      timestamp: 2.minutes.ago.strftime(TIMESTAMP_FORMAT),
      verb: { id: Xapi::VERB_INITIALIZED },
      object: { objectType: 'Activity', id: 'https://netexlearning.com/487203' }
    }
  end
  let(:request_params) { statement.merge(actor: actor) }
  let(:request_env) { {} }

  def basic_auth_headers
    auth_string = ActionController::HttpAuthentication::Basic.encode_credentials(
      username, user_password
    )
    { 'HTTP_AUTHORIZATION' => auth_string }
  end

  def do_request
    put '/xapi/statements', params: request_params, headers: basic_auth_headers
  end

  describe 'PUT /xapi/statement' do
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
          expect { do_request }.to raise_error(ArgumentError, 'invalid attempt_id')
        end
      end

      context 'when an attempt exists,' do
        let(:attempt) { create(:attempt, user: user) }
        let(:statement_writer) { instance_double(Xapi::StatementWriter) }

        before do
          allow(Xapi::StatementWriter).to receive(:new).and_return(statement_writer)
        end

        class SerializedJsonMatcher
          def initialize(expected_json)
            @expected_json = expected_json
          end

          def ===(other)
            # other is an ActionController::Parameters instance
            params = other.to_h.except('action', 'controller').to_json
            @expected_json == JSON.parse(params, symbolize_names: true)
          end
        end

        it 'saves the statement using a statement writer' do
          allow(statement_writer).to receive(:write).and_return(true)
          do_request
          expect(Xapi::StatementWriter).to have_received(:new) do |arg|
            # arg is an instance of ActionController::Parameters.
            # Call .to_h to filter out unpermitted params
            # result = arg.to_h.deep_symbolize_keys
            # expect(result).to eq(request_params)
            result = JSON.parse(arg.to_h.to_json, symbolize_names: true)
            expect(result).to eq(request_params)
          end
        end

        context 'when the statement does not conflict with existing statements,' do
          it 'saves the statement and responds with a status of "204 - no_content"' do
            allow(statement_writer).to receive(:write).and_return(true)
            do_request
            expect(response).to have_http_status(:no_content)
          end
        end

        context 'when the statement conflicts with existing statements,' do
          it 'saves the statement and responds with a status of "409 - conflict"' do
            allow(statement_writer).to receive(:write).and_return(false)
            do_request
            expect(response).to have_http_status(:conflict)
          end
        end
      end
    end
  end
end
