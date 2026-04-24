module Smartbook
  class LongFillInResponseParser < ResponseParser
    def question_type
      'open_ended'
    end

    # All fill-in-the-blank and open-ended subactivities have the same interaction type;
    # the ones that the instructor needs to grade have the indicated response patter
    def instructor_gradable?
      !correct_response_pattern
    end

    def formatted_correct_response
      # the correctResponsePattern is an array if there is one
      formatted_response(correct_response_pattern) unless instructor_gradable?
    end

    # make sure this does not fail if there is no response in the results;
    # also how to handle an unanswered question? Do we filter out the "undefined" string?
    def formatted_student_response
      formatted_response(raw_response) if raw_response
    end

    private def formatted_response(unformatted_response)
      unformatted_response.gsub(/\[.\]/, ' ').gsub(/undefined/, ' ')
    end

    private def raw_response
      return @raw_response if defined? @raw_response
      @raw_response = scorm_extensions[:response] if result
    end
  end
end
