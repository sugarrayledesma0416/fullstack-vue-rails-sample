module Smartbook
  class MatchingResponseParser < ResponseParser
    RESPONSES_SEPARATOR = '[,]'.freeze
    QUESTION_ANSWER_SEPARATOR = '[.]'.freeze
    SOURCE_TARGET_RESPONSE_REG_EXP = /([a-f0-9]{32})\[\.\]([a-f0-9]{32}|true|false)/

    def question_type
      'matching'
    end

    def formatted_correct_response
      ''
    end

    def formatted_student_response
      ''
    end

    def all_correct?
      @all_correct ||= incorrect_response_count.zero?
    end

    def incorrect_response_count
      @incorrect_response_count ||= entries.sum do |entry|
        entry[:response] == entry[:student_response] ? 0 : 1
      end
    end

    def entries
      @entries ||= prompts.map.with_index do |prompt, index|
        {
          prompt: prompt,
          response: correct_responses[index],
          student_response: student_responses[index]
        }
      end
    end

    private def correct_responses
      @correct_responses ||= parse_responses_string(correct_response_pattern)
    end

    private def student_responses
      @student_responses ||= parse_responses_string(raw_response || '')
    end

    private def parse_responses_string(responses)
      if definition[:source].present?
        responses_mapping = responses.split(RESPONSES_SEPARATOR).map do |response|
          matching = SOURCE_TARGET_RESPONSE_REG_EXP.match(response)
          [matching[1], targets_descriptions[matching[2]]]
        end.to_h
        sources_descriptions.keys.map do |key|
          responses_mapping[key]
        end
      else
        # Word search activity
        responses.split(RESPONSES_SEPARATOR, -1)
      end
    end

    private def prompts
      if definition[:source].present?
        sources_descriptions.values
      else
        Array.new(correct_responses.count) { '' }
      end
    end

    private def sources_descriptions
      @sources_descriptions ||= definition[:source].map do |entry|
        [
          entry[:id],
          ApplicationController.helpers.html_strip_and_decode(description(entry))
        ]
      end.to_h
    end

    private def targets_descriptions
      @targets_descriptions ||= definition[:target].map do |entry|
        [
          entry[:id],
          ApplicationController.helpers.html_strip_and_decode(description(entry))
        ]
      end.to_h
    end

    private def correct_response_pattern
      definition[:correctResponsesPattern][0]
    end
  end
end
