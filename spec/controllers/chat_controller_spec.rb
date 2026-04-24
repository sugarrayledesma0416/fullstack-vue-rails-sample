describe ChatController do
  describe '#create_session' do
    let(:user) { build_stubbed(:student) }
    let(:pnub_client_wrapper) do
      instance_double(Pnub::ClientWrapper, create_grants: true, grants_ttl: 1440)
    end
    let(:auth_cache) { instance_double(VhlChat::AuthCache, store_auth: true) }
    let(:group_membership_key) { "#{user.id}-a_unique_key_from_api" }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:group_membership_key).and_return(group_membership_key)
      allow(Pnub::ClientWrapper).to receive(:new).and_return(pnub_client_wrapper)
      allow(pnub_client_wrapper).to receive(:chat_session_data).and_return([])
      allow(M3::Application.config).to receive(:chat_auth_cache)
        .and_return(instance_double(Redis))
      allow(VhlChat::AuthCache).to receive(:new).and_return(auth_cache)
    end

    def do_request
      fake_login(user)
      post :create_session
    end

    context 'when the user does not have any vhl chat courses associated,' do
      it 'renders an error with code 428: precondition required' do
        allow(user).to receive(:pubnub_cilent_roster)
          .and_return(roster: { groups: [] })

        error_message = 'The user needs at least one chat course association'

        do_request
        expect(response.status).to eq 428
        expect(response.content_type).to eq 'application/json; charset=utf-8'
        expect(response.body).to eq({ error: error_message }.to_json)
      end
    end

    context 'when grants are successful,' do
      let(:chat_group) do
        {
          chat_level: 'partner_chat',
          id: 1,
          name: 'course_name',
          program_id: 1,
          sections: {}
        }
      end

      before do
        allow(pnub_client_wrapper).to receive(:grants_successful?).and_return(true)
        allow(pnub_client_wrapper).to receive(:to_json).and_return({})
        allow(user).to receive(:pubnub_client_roster)
          .and_return(roster: { groups: [chat_group] })
      end

      it 'renders client json' do
        do_request
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/json; charset=utf-8'
        expect(response.body).to match '{}'
      end

      it 'stores values in the cache and sets the TTL' do
        expected_ttl = 86_400 # 24 hours in seconds
        do_request
        expect(auth_cache).to have_received(:store_auth).with(
          group_membership_key, pnub_client_wrapper.chat_session_data, expected_ttl
        )
      end
    end

    context 'when grants fail,' do
      let(:chat_group) do
        {
          chat_level: 'partner_chat',
          id: 1,
          name: 'course_name',
          program_id: 1,
          sections: {}
        }
      end

      before do
        allow(pnub_client_wrapper).to receive(:grants_successful?).and_return(false)
        allow(pnub_client_wrapper).to receive(:grant_responses_with_errors)
          .and_return('errors': 'something bad happened')
        allow(user).to receive(:pubnub_client_roster)
          .and_return(roster: { groups: [chat_group] })
      end

      it 'renders json with errors' do
        do_request
        expect(response.status).to eq 403
        expect(response.body).to match '{"errors":"something bad happened"}'
      end
    end
  end
end
