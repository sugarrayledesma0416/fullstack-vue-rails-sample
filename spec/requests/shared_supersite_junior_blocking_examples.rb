shared_examples 'prevents access for supersite junior programs' do
  it 'sets a flash error and redirects to the default path ' \
     'when current program is a supersite junior program' do
    target_user = (
      defined?(user) && user ||
      defined?(instructor) && instructor ||
      defined?(student) && student
    )

    program.update!(family: 'supersites_jr')

    do_request

    expect(flash[:error]).to eq(
      ApplicationController::BLOCKED_SUPERSITE_JUNIOR_MESSAGE
    )
    expect(response).to redirect_to(
      BestDefaultPath.best_default_path(target_user, program, nil, {})
    )
  end
end
