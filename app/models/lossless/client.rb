module Lossless
  class Client
    # Store the connection in a class variable so it can be re-used.
    def self.connection
      @connection ||= ConnectionHandler.connection(
        basic_auth: ['m3', M3::Application.config.lossless_api_password],
        request_type: :json,
        uri: URI(Rails.application.config.lossless_base_url)
      )
    end

    def get_token(cache_key)
      request_with_error_handling(
        path: "/m3/policy/#{cache_key}", verb: :get
      ) do |response|
        response.body['token'].to_s
      end
    end

    def send_policy(policy_body)
      request_with_error_handling(
        body: policy_body, path: '/m3/policy', verb: :post
      ) do |response|
        response.body['token'].to_s
      end
    end

    def delete_user_data(user_id)
      request_with_error_handling(
        path: "/m3/delete_user_data/#{user_id}", verb: :post
      ) do |response|
        response.success?
      end
    end

    def delete_school_data(school_id)
      request_with_error_handling(
        path: "/m3/delete_school_data/#{school_id}", verb: :post
      ) do |response|
        response.success?
      end
    end

    def delete_virtual_chat_recordings(audio_paths)
      request_with_error_handling(
        body: { audio_paths: },
        path: '/m3/delete_virtual_chat_recordings',
        verb: :post
      ) do |response|
        response.success?
      end
    end

    def transfer_student_work(user_id, section_from, section_to)
      request_with_error_handling(
        body: {
          new_section_guid: section_to.guid, old_section_guid: section_from.guid
        },
        path: "/m3/student_work_transfer/#{user_id}",
        verb: :post
      ) do |response|
        response.success?
      end
    end

    # Takes a hash instead of specifying position-based arguments so
    # the request args can more easily be reported in case of error.
    private def request_with_error_handling(request_args)
      response = run_request(**request_args)

      if response.success?
        yield response
      else
        VHLMonitor.error(response: response.env.to_h.except(:response), request: request_args)
        nil
      end
    rescue StandardError => e
      VHLMonitor.notify(e, request: request_args)
      nil
    end

    private def run_request(verb:, path:, body: nil, headers: nil)
      self.class.connection.run_request(verb, path, body, headers)
    end
  end
end
