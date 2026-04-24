describe UserSessionsController do
  describe '#remote_destroy' do
    let(:user) { build_stubbed(:user) }
    let(:service_ticket) { 'ST-1336076277rEEAB2CC9DE6A59E7A1' }
    let(:valid_logout_request_xml) do
      '<samlp:LogoutRequest ID="abcd" Version="2.0" IssueInstant="valid_time">
        <saml:NameID></saml:NameID>
        <samlp:SessionIndex>' + service_ticket + '</samlp:SessionIndex>
        </samlp:LogoutRequest>'
    end

    def do_request(params)
      post remote_logout_path, params: params
    end

    # tests for this action need to be integration tests, because we first
    # need to create a real session object by logging in as user, then test
    # deletion of that session via service call to this action

    it 'is successful' do
      do_request({})
      expect(response).to be_ok
    end

    it 'is successful with an unencoded logoutRequest param' do
      do_request('logoutRequest' => valid_logout_request_xml)
      expect(response).to be_ok
    end

    it 'is successful with an encoded logoutRequest param' do
      do_request(
        'logoutRequest' => URI.encode_www_form_component(valid_logout_request_xml)
      )
      expect(response).to be_ok
    end
  end
end
