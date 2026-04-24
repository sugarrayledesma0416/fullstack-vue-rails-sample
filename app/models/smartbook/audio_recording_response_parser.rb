module Smartbook
  class AudioRecordingResponseParser < ResponseParser
    def question_type
      'voice_recording'
    end

    def instructor_gradable?
      true
    end

    def formatted_student_response
      raw_response
    end
  end
end
