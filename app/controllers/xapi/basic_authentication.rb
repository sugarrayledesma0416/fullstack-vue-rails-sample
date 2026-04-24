module Xapi
  module BasicAuthentication
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    def authenticate_xapi
      authenticate_or_request_with_http_basic do |username, password|
        BasicAuthCredential.valid_credentials?(username, password)
      end
    end
  end
end
