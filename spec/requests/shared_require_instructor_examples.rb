require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

shared_examples 'require program access for instructor' do
  it 'redirects to the access problem page when logged-in user ' \
     'is an instructor without access to the specified program' do
    no_access_instructor = create(:instructor)
    log_in_user_with_access_to_programs(no_access_instructor, [])

    do_request

    expect(response).to redirect_to(%r{/access_problem/#{program.id}})
  end
end

# The optional format argument currently supports only one value, :json,
# and is needed because CASClient::Frameworks::Rails::Filter class has a
# method, unauthorized!, that works differently when the request format
# is :json.
# This has to be passed along to the 'require logged in user' examples,
# where the expectations are evaluated.
shared_examples 'require instructor with program access' do |format|
  include_examples 'require logged in user', format
  include_examples 'require program access for instructor'

  it 'sets a flash error and redirects to the default student path ' \
     'when logged-in user is not an instructor' do
    student = create(:student)
    log_in_user_with_access_to_programs(student, [program])

    do_request

    if format == :json
      expect(response).to be_unauthorized
      expect(response.body).to eq(
        'User must have Instructor access.'
      )
    else
      expect(flash[:error]).to eq(
        ApplicationController::INSTRUCTOR_ACCESS_REQUIRED_MESSAGE
      )
      expect(response).to redirect_to(
        BestDefaultPath.best_default_path(student, program, nil, session)
      )
    end
  end
end

# The require_instructor_or_grader before_action method has a different
# redirect url to the require_instructor method, so requires a different
# test. However there aren't any grader accounts any more so it's not worth
# testing the case wehre current_user.grader? is true.
shared_examples 'require instructor or grader with program access' do
  include_examples 'require logged in user'
  include_examples 'require program access for instructor'

  it 'sets a flash error and redirects to the ua home path ' \
     'when logged-in user is not an instructor' do
    student = create(:student)
    log_in_user_with_access_to_programs(student, [program])

    do_request

    expect(flash[:error]).to eq(
      ApplicationController::INSTRUCTOR_ACCESS_REQUIRED_MESSAGE
    )
    expect(response).to redirect_to(ua_home_path)
  end
end

shared_examples 'require instructor with no assistant role' do
  it 'sets a flash error and redirects to the instructor dashboard path ' \
     'when logged-in user is an assistant' do
    assistant = create(:section_assistant, section: section)
    log_in_user_with_access_to_programs(assistant.instructor, [program])

    do_request

    expect(flash[:error]).to eq(
      ApplicationController::INSTRUCTOR_ACCESS_REQUIRED_MESSAGE
    )
    expect(response).to redirect_to(instructor_dashboard_path)
  end
end
