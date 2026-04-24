module Smartbook
  class Response
    SANTILLANA_BUCKET_PREFIX = '//santillanausa.s3.amazonaws.com/'.freeze

    attr_accessor :statement, :rack_env

    delegate :<=>, :formatted_correct_response, :formatted_student_response,
             :html_friendly_prompt, :points_earned, :points_possible, :primary_question_number,
             :prompt, :question_number, :question_type, :score, :submission_time,
             :subpart_question_number, to: :response_parser

    def initialize(statement, rack_env = {})
      self.statement = statement
      self.rack_env = rack_env
    end

    # label needs to be something that
    # can be turned into a symbol.
    # so it can't start with a number
    # and cannot contain dashes.
    def subactivity_id
      @subactivity_id ||= 'int_' + interaction_id
    end

    # use this to drive the SB iframe to the page
    # holding a specific interaction
    def interaction_id
      # pattern is activity_id/interaction_id
      # # e.g. "52352/interaction/22dd3c2c9bb5f4387dbc412b9b95518f"
      @interaction_id ||= statement.object.id.split(/\//).last
    end

    def label
      "question_#{question_number}"
    end

    def partial_name
      'smartbook'
    end

    def answered?
      statement.verb == Xapi::VERB_ANSWERED
    end

    def subactivity_type
      @subactivity_type ||= statement.object.definition.interactionType
    end

    # this will return true only if the subactivity has been answered and has no score;
    # conditions that indicate an instructor-graded interaction.
    def instructor_gradable?
      answered? && response_parser.instructor_gradable?
    end

    def auto_graded?
      answered? && !response_parser.instructor_gradable?
    end

    # TODO do we need to handle the case where there is no subactivity_type -
    # e.g. response is unanswered, raise error?
    def response_parser
      if answered?
        @response_parser ||=
          case subactivity_type
          when 'long-fill-in'
            LongFillInResponseParser.new(statement)
          when 'choice'
            ChoiceResponseParser.new(statement)
          when 'matching'
            MatchingResponseParser.new(statement)
          else
            if audio_recording_subactivity?
              AudioRecordingResponseParser.new(statement)
            elsif drawing_subactivity?
              DrawingResponseParser.new(statement)
            else
              raise NotImplementedError, "unknown subactivity_type: '#{subactivity_type}'"
            end
          end
      end
    end

    private def audio_recording_subactivity?
      response = subactivity_type == 'other' && statement.result.dig(
        :response
      )
      return false unless response

      if response.start_with?(audio_recording_response_prefix)
        true
      elsif response.start_with?(SANTILLANA_BUCKET_PREFIX)
        log_non_lossless_recording
        true
      end
    end

    private def log_non_lossless_recording
      VHLMonitor.warning(
        'Non-lossless smartbook recording detected',
        attempt_id: statement.attempt_id,
        statement_attrs: JSON.parse(statement.serialized_attrs || '{}')
      )
    end

    private def drawing_subactivity?
      subactivity_type == 'other' && statement.result.dig(
        :extensions,
        DrawingResponseParser::SCORM_EXTENSIONS_TCDRAW_KEY
      ).present?
    end

    private def audio_recording_response_prefix
      Rails.application.config.smartbook_recording_endpoint
    end
  end
end
