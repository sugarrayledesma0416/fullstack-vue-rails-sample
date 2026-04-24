require 'net/http'

module Vitalsource
  class Client
    def initialize(access_token = nil)
      @access_token = access_token
    end

    def post(path, body)
      do_request('Post', path) do |request|
        request.body = body
      end
    end

    def get(path)
      do_request('Get', path)
    end

    private def do_request(request_klass, path)
      uri = URI("#{config.api_url}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = new_request(request_klass, uri)
      yield request if block_given?
      assign_headers(request)
      response = http.request(request)
      # SINCE: 2024-02-13
      # BY: Adam Alboyadjian
      # The logging is being disabled to cut down on our Rollbar usage.
      # The events aren't being actively monitored and the
      # integration seems to be working without any problems.
      # log(uri, request, response)
      parse_response(response)
    end

    private def config
      Vitalsource.config
    end

    private def new_request(request_klass, uri)
      "Net::HTTP::#{request_klass}".constantize.new(uri.path)
    end

    private def assign_headers(request)
      request.content_type = 'text/xml'
      request['X-VitalSource-API-Key'] = config.api_key
      @access_token && request['X-VitalSource-Access-Token'] = @access_token
    end

    private def log(uri, request, response)
      VHLMonitor.info('Vitalsource API Request',
                      uri: uri.to_s,
                      method: request.method,
                      request_body: request.body,
                      response_status: response.code,
                      response_body: response.body)
    end

    private def parse_response(response)
      if response.code == '200'
        response_xml = Nokogiri::XML.parse(response.body)
        if response_xml.root.name == 'error-response'
          error_to_hash(response_xml)
        else
          response_xml
        end
      else
        { error_code: response.code.to_i }
      end
    end

    private def error_to_hash(response_xml)
      {
        error_code: response_xml.at('error-code').content.to_i,
        error_message: response_xml.at('error-text').content
      }
    end
  end
end
