module AI
  module LiveData
    class GradingInputValidator
      attr_reader :attempt, :errors, :question_label

      delegate(:activity, to: :attempt)

      def initialize(attempt:, question_label:)
        @attempt = attempt
        @question_label = question_label
        @errors = []
      end

      def valid?
        return @valid if defined? @valid

        if question.blank?
          errors << 'Invalid question label'
        elsif !attempt.results&.has_response?(question.label)
          errors << 'No student response'
        end

        @valid = errors.empty?
      end

      def response
        return @response if defined? @response

        @response = attempt.results&.response(question.label)
      end

      def question
        @question ||= content_object.questions.detect do |question|
          question.label == question_label
        end
      end

      private def content_object
        activity.content_object
      end
    end
  end
end
