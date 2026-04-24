module BasicAuthLogin
  shared_context 'with basic auth' do
    let(:basic_auth) { ActionController::HttpAuthentication::Basic }

    before do
      stub_const('HTTP_AUTHENTICATIONS', { 'maestro' => 'secret' })
    end
  end

  # login and bad_login work in request spec headers:
  # include_context 'with basic auth'
  # get "/foo/bar", as: :json, headers: login
  def login
    {
      HTTP_AUTHORIZATION: basic_auth.encode_credentials(http_user, http_password)
    }
  end

  def bad_login
    {
      HTTP_AUTHORIZATION: basic_auth.encode_credentials('foo', 'bar')
    }
  end

  # This works in controller specs:
  # include_context 'with basic auth'
  # before do
  #   add_auth_header(request)
  # end
  def add_auth_header(request)
    request.headers['HTTP_AUTHORIZATION'] = basic_auth.encode_credentials(http_user, http_password)
  end

  private def http_user
    HTTP_AUTHENTICATIONS.keys.first
  end

  private def http_password
    HTTP_AUTHENTICATIONS[http_user]
  end
end
