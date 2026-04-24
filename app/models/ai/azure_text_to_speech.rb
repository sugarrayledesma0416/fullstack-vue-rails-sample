module AI
  class AzureTextToSpeech
    # REST API wrapper for Azure text to speech REST API
    # https://learn.microsoft.com/en-us/azure/ai-services/speech-service/rest-text-to-speech

    def list_voices
      response = connection.get(voice_uri) do |req|
        req.headers['Ocp-Apim-Subscription-Key'] = subscription_key
        req.headers['Accept'] = 'application/json'
      end

      # Server errors are not recoverable. Either the code contains errors
      # or the authorization token is invalid.
      raise "Server error: #{response.status}" if response.status != 200

      response.body
    end

    def generate_from_ssml(ssml)
      response = connection.post(uri, ssml) do |req|
        req.headers['Content-Type'] = 'application/ssml+xml'
        req.headers['Ocp-Apim-Subscription-Key'] = subscription_key
        req.headers['User-Agent'] = 'Faraday'
        req.headers['X-Microsoft-OutputFormat'] = 'riff-44100hz-16bit-mono-pcm'
      end

      # Server errors are not recoverable. Either the code contains errors
      # or the authorization token is invalid.
      raise "Server error: #{response.status}" if response.status != 200

      response.body
    end

    private def region
      Rails.application.config.azure_speech_service_region
    end

    private def uri
      "https://#{region}.tts.speech.microsoft.com/cognitiveservices/v1"
    end

    private def voice_uri
      "https://#{region}.tts.speech.microsoft.com/cognitiveservices/voices/list"
    end

    private def subscription_key
      Rails.application.config.azure_speech_service_api_key
    end

    private def connection
      Faraday.new do |f|
        f.request :multipart, flat_encode: true
        f.adapter :net_http
        f.response :json, content_type: /\bjson$/
      end
    end
  end
end
