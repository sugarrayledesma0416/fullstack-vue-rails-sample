module OneRoster
  class Client
    CLASSES_ENDPOINT = '/one_roster_api/classes'.freeze
    attr_accessor :username
    attr_reader :last_request_status, :last_request_errors

    def initialize(username=nil)
      self.username = username
    end

    def courses_for_school(school_salesforce_id)
      validate_attributes
      results = do_request('/one_roster_api/courses', username: username,
                                                      school_salesforce_id: school_salesforce_id)
      ensure_response(results, 'courses')
    end

    def classes_for_course(school_salesforce_id, course_external_id)
      results = do_request(CLASSES_ENDPOINT, course_sourced_id: course_external_id,
                           school_salesforce_id: school_salesforce_id)
      ensure_response(results, 'classes')
    end

    def last_request_successful?
      @last_request_status == 200
    end

    def school_inactive?
      @last_request_status == 422
    end
    
    private def validate_attributes
      raise 'username is required' if username.blank?
    end

    private def do_request(endpoint, additional_params = {})
      connection = ConnectionHandler.connection(
        basic_auth: [
          Rails.configuration.ra_api_username,
          Rails.configuration.ra_api_password
        ],
        request_type: :json,
        uri: RA_URL
      )
      response = connection.get(endpoint, additional_params)
      @last_request_status = response.status
      log_error(response.body, endpoint, additional_params) if @last_request_status != 200
      response.body
    end

    private def log_error(response_body, endpoint, additional_params)
      @last_request_errors = ensure_response(response_body, 'errors')
      VHLMonitor.warning(
        'Fail response from RosterAssistant',
        additional_params.merge(endpoint: endpoint,
                                errors: @last_request_errors,
                                response_status: @last_request_status)
      )
    end

    private def ensure_response(response, key)
      response.fetch(key, nil) if response.respond_to?(:fetch)
    end
  end
end
