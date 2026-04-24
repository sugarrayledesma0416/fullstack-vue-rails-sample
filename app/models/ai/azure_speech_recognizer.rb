module AI
  class AzureSpeechRecognizer
    # REST API wrapper for Azure speech recognition REST API for short audio (less
    # than 60 seconds).
    # https://learn.microsoft.com/en-us/azure/ai-services/speech-service/rest-speech-to-text-short
    attr_reader :filename, :language, :reference_text, :sample_rate

    def initialize(filename:, sample_rate:, language:, reference_text: nil)
      @filename = filename
      @sample_rate = sample_rate
      @language = language
      @reference_text = reference_text
    end

    def recognize
      payload = Faraday::Multipart::FilePart.new(filename, mime_type)

      response = connection.post(uri, payload) do |req|
        req.headers['Content-Type'] = content_type
        req.headers['Ocp-Apim-Subscription-Key'] = Rails.application.config.azure_speech_service_api_key
        req.headers['Transfer-Encoding'] = 'chunked'
        req.headers['Expect'] = '100-continue'
        req.headers['Accept'] = 'application/json'
        req.headers['Pronunciation-Assessment'] = Base64.strict_encode64(
          pronunciation_assessment.to_json
        )
      end

      # Server errors are not recoverable. Either the code contains errors
      # or the authorization token is invalid.
      raise "Server error: #{response.status}" if response.status != 200

      response.body
    end

    private def file_extension
      @file_extension ||= File.extname(filename)
    end

    private def mime_type
      case file_extension
      when '.wav' then 'audio/wav'
      when '.ogg' then 'audio/ogg'
      else
        raise ArgumentError, "Unsupported file extension '#{file_extension}'"
      end
    end

    private def content_type
      case file_extension
      when '.wav' then "audio/wav; codecs=audio/pcm; samplerate=#{sample_rate}"
      when '.ogg' then 'audio/ogg; codecs=opus'
      else
        raise ArgumentError, "Unsupported file extension '#{file_extension}'"
      end
    end

    # https://learn.microsoft.com/en-us/azure/ai-services/speech-service/rest-speech-to-text-short#pronunciation-assessment-parameters
    private def pronunciation_assessment
      {
        Dimension: 'Comprehensive',
        EnableMiscue: 'True',
        GradingSystem: 'HundredMark',
        Granularity: 'Word'
      }.tap do |memo|
        memo[:ReferenceText] = reference_text if reference_text
      end
    end

    private def uri
      "https://#{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=#{language}&format=detailed"
    end

    private def region
      Rails.application.config.azure_speech_service_region
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
