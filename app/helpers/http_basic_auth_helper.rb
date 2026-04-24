module HttpBasicAuthHelper
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  def basic_auth_valid?(username, password)
    valid_password = HTTP_AUTHENTICATIONS[username]

    # Invalid user.
    if valid_password.nil?
      false
    # Old style: A single password string associated with user.
    elsif valid_password.is_a?(String)
      password == valid_password
    # New style: One or more valid passwords in an array to facilitate
    # password rotation.
    else
      valid_password.any? do |pw|
        password == pw
      end
    end
  end

  def http_basic_authenticate
    authenticate_or_request_with_http_basic do |uname, pwd|
      basic_auth_valid?(uname, pwd)
    end
  end
end
