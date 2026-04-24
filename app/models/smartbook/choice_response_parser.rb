module Smartbook
  class ChoiceResponseParser < ResponseParser
    def question_type
      'multiple_choice'
    end

    def formatted_correct_response
      formatted_response(correct_response_pattern)
    end

    # make sure this does not fail if there is no response in the results
    def formatted_student_response
      formatted_response(raw_response) if raw_response
    end

    private def formatted_response(unformatted_response)
      unformatted_response.gsub(/\[.\]/, ' ')
    end

    private def raw_response
      return @raw_response if defined? @raw_response
      @raw_response = scorm_extensions[:response] if result
    end
  end
end
