require 'requests/login_helper_methods'

# The optional format argument currently supports only one value, `:json`,
# and is needed because CASClient::Frameworks::Rails::Filter class has a
# method, unauthorized!, that works differently when the request format
# is :json.
shared_examples 'require logged in user' do |format|
  it 'redirects to the login page without a logged in user' do
    do_request

    if format == :json
      expect(response).to be_unauthorized
    else
      expect(response).to redirect_to(%r{/login})
    end
  end
end

shared_examples 'require program access' do
  it 'redirects to the access problem page when logged-in user ' \
     'is a user without access to the specified program' do
    no_access_user = create(:user)
    log_in_user_with_access_to_programs(no_access_user, [])

    do_request

    expect(response).to redirect_to(%r{/access_problem/#{program.id}})
  end
end
