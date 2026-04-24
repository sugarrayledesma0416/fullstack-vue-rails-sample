class DeveloperConstraint
  def matches?(request)
    return false unless request.session.key?(:cas_user)

    user = User.find_by(username: request.session.fetch(:cas_user))
    user&.developer?
  end
end
