describe HealthCheckController do
  describe '#health_check' do
    before do
      # Configure HTTP basic authentication.
      user = 'maestro_ryhag'
      password = 'test'
      HTTP_AUTHENTICATIONS[user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
    end

    it 'tests that essential components are working' do
      get :health_check

      expect(response.status).to eq 200
    end
  end

  describe '#elb_health_check' do
    before do
      HTTP_AUTHENTICATIONS['elb_token'] = 'test'
    end

    context 'given the secret token' do
      it 'tests that the stack is loaded' do
        get :elb_health_check, params: { token: HTTP_AUTHENTICATIONS['elb_token'] }
        expect(response.status).to eq 200
        expect(response.body).to eq "Get me my swimmies, I'm going in the pool!"
      end
    end

    context 'with the wrong secret token' do
      it 'returns a 403' do
        get :elb_health_check, params: { token: HTTP_AUTHENTICATIONS['elb_token'].reverse }
        expect(response.status).to eq 403
      end
    end
  end
end
