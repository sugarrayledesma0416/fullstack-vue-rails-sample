module Smartbook
  class ResponseParser
    SCORM_EXTENSIONS_KEY = 'http://scorm.com/extensions/usa-data'.to_sym.freeze
    ANALYTICS_ACTIVITY_POSSIBLE_KEYS = %i[Activity Actividad].freeze
    # For reference, here are the different analytics keys:
    # :Product or :Producto, :Level or :Nivel, :Unit or :Unidad,
    # :Section or :Seccion, :'Modes of Communication', :'Learning Objectives'
    #
    DESCRIPTION_POSSIBLE_KEYS = %i[en es].freeze
    attr_accessor :statement

    delegate :result, :object, :verb, :answered?, to: :statement
    delegate :definition, to: :object

    def initialize(statement)
      @statement = statement
    end

    def prompt
      ApplicationController.helpers.html_strip_and_decode(description_attr)
    end

    alias html_friendly_prompt prompt

    def question_number
      @question_number ||= analytics_attr(
        ANALYTICS_ACTIVITY_POSSIBLE_KEYS
      ).sub(/^[0]+/, '')
    rescue StandardError => e
      # recover from this error; send Rollbar warning of
      # bad activity; assign a question number;
      # if the statement has already been stored we will have an attempt id to log also
      # SINCE: 2024-02-13
      # BY: Adam Alboyadjian
      # The logging is being disabled to cut down on our Rollbar usage.
      # The events aren't being actively monitored.
      # Rollbar.warn(
      #   'Requires TECH PROD FIX: Missing analytics element in activity: ' \
      #   "#{statement.activity_id} attempt_id: #{statement.attempt_id}"
      # )
      @question_number = statement.activity_id.split(/\//).last
    end

    # e.g. if question number is 93a,
    # returns 93 to be used for sorting
    def primary_question_number
      # if the number is all digits
      # convert to int for sorting
      if question_number_all_digits?
        question_number.to_i
      else
        # return everything except the last character
        # which is a letter of the alphabet
        question_number[0..-2].to_i
      end
    end

    # e.g. if question number is 93a,
    # returns 'a' to be used for sorting
    def subpart_question_number
      question_number.last(1) unless question_number_all_digits?
    end

    def points_possible
      MaestroActivityEngine::ActivityContent::SmartBookContent.points_possible_for_question_type(
        question_type
      )
    end

    def submission_time
      statement.timestamp
    end

    # Only certain long fill in the blank subactivities and recordings
    # are instructor-graded
    def instructor_gradable?
      false
    end

    def score
      @score ||= if instructor_gradable?
                   0
                 else
                   statement.score[:raw].to_f / statement.score[:max].to_f
                 end
    end

    def points_earned
      score * points_possible
    end

    def formatted_correct_response
      raise NotImplementedError
    end

    # needs to be implemented by subclasses;
    # there is no default parsing pattern
    def formatted_student_response
      raise NotImplementedError
    end

    def <=>(other_response)
      if primary_question_number == other_response.primary_question_number
        subpart_question_number <=> other_response.subpart_question_number
      else
        primary_question_number <=> other_response.primary_question_number
      end
    end

    # correct result pattern will be taken from the results of an answered
    # subactivity as opposed to the definition so that it is formatted the
    # same way that the student's response is formatted.
    # e.g.
    # @submission_data[:object][:definition][:correctResponsesPattern]
    # "amigos[,]hermanos[,]amigas[,]madre[,]hermana[,]hermano"
    # vs.
    # result[:extensions][SCORM_EXTENSIONS_KEY][:correctResponsesPattern]
    # ""1.[.]usted[,]2.[.]usted[,]3.[.]tú[,]4.[.]tú[,]5.[.]usted""
    private def correct_response_pattern
      return @correct_response_pattern if defined? @correct_response_pattern
      @correct_response_pattern = scorm_extensions[:correctResponsesPattern] if result
    end

    # the result block will only be present if the subactivity was answered;
    # so caller should ensure this is so before calling any of the student
    # response handling methods;
    # the response will be taken from the extensions element instead of the response
    # element so that properly reflects unanswered questions.
    # e.g. Choice subactivity
    # result[:response]
    # list of answer ids but no indication of which were left unanswered
    # "5ba89c0edf88fa426bd1a660230620d7[,]9d53d67d82f9456c6d1f2710214ef16b[,]
    # a814e4etob62ffee42fe308f65c7ffd996[,]a983f9b57868564e47b307eee8ed4b33"
    # contrast with:
    # result[:extensions][SCORM_EXTENSIONS_KEY][:response]
    # from this it is clear that the student did not answer #2
    # "1.[.]usted[,]3.[.]tú[,]4.[.]tú[,]5.[.]usted"
    #
    # e.g. Long fill-in autograded activity - 2 left unanswered
    # result[:response]
    # "ella[,]ellas[,]ellos[,]ellas[,]él[,]ellos"
    # result[:extensions][SCORM_EXTENSIONS_KEY][:response]
    # "1.[.]ella[,]2.[.]ellas[,]3.[.]ellos[,]4.[.]ellas[,]5.[.]él[,]6.[.]ellos[,]
    # 7.[.]undefined[,]8.[.]undefined"
    # NOTE: "undefined"" is inserted in place of empty answer for long-fill-in,
    # where choice just omits it altogether
    private def raw_response
      return @raw_response if defined? @raw_response
      @raw_response = result.response if result
    end

    private def scorm_extensions
      @scorm_extensions ||= result[:extensions][SCORM_EXTENSIONS_KEY]
    end

    private def question_number_all_digits?
      question_number.match(/\A\d+\z/)
    end

    # Return the analytics value for the first existing key.
    private def analytics_attr(possible_keys)
      key = possible_keys.detect { |key| analytics.key?(key) }
      analytics[key]
    end

    private def analytics
      @analytics ||= scorm_extensions[:analytics]
    end

    # description can be defined as English or Spanish;
    # Return the description value found for either
    def description_attr
      description(definition)
    end

    def description(entry)
      key = DESCRIPTION_POSSIBLE_KEYS.detect { |key| entry[:description].key?(key) }
      entry[:description][key]
    end
  end
end
