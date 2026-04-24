module Smartbook
  # https://xapi.com/blog/new-experiment-tin-can-draw
  class DrawingResponseParser < ResponseParser
    SCORM_EXTENSIONS_TCDRAW_KEY = 'http://scorm.com/extensions/tcdraw-data'.to_sym.freeze

    def question_type
      'drawing'
    end

    def instructor_gradable?
      true
    end

    def formatted_student_response
      result[:extensions][SCORM_EXTENSIONS_TCDRAW_KEY][:image]
    end
    alias image_src formatted_student_response
  end
end
