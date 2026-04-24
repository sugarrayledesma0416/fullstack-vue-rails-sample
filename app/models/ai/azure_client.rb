module AI
  class AzureClient
    REGION = 'eastus'.freeze
    HOST = 'api.cognitive.microsoft.com'.freeze
    SCOPED_TOKEN_URL = '/sts/v1.0/issueToken'.freeze
    # Default expiration duration according to the microsoft documentation
    DEFAULT_EXPIRES_IN = 10 * 60

    # Issue a temporary token with scope limited to speech recognition
    def scoped_token
      return @scoped_token if defined? @scoped_token

      response = connection_with_auth.post(
        "https://#{REGION}.#{HOST}#{SCOPED_TOKEN_URL}"
      )
      @scoped_token = if response.success?
                        {
                          token: response.body,
                          expires_in: DEFAULT_EXPIRES_IN
                        }
                      end
    rescue StandardError => e
      Rails.logger.error("Failed to fetch temporary token: #{e.message}")
      @scoped_token = nil
    end

    private def connection_with_auth
      @connection_with_auth ||= Faraday.new(faraday_ssl_opts) do |faraday|
        faraday.headers['Ocp-Apim-Subscription-Key'] = Rails.application.config.azure_speech_service_api_key
        faraday.headers['Content-Type'] = 'application/json'
        faraday.use :instrumentation
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end

    # Allow self-signed ssl certificates when not running in production.
    # :nocov:
    private def faraday_ssl_opts
      if Rails.env.live?
        {}
      else
        { ssl: { verify: false } }
      end
    end
    # :nocov:
  end
end
