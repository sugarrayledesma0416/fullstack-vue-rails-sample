require 'requests/login_helper_methods'

shared_examples 'require a question bank editor' do
  it 'redirects a user who is not a question bank editor' do
    log_in_user(user)
    do_request

    expect(response).to redirect_to '/403'
  end
end
