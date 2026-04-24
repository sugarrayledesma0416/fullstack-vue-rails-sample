module AI
  module GradingSuggestionGenerators
    class OpenEndedQuestionGenerator
      attr_reader :attempt, :grading_suggestion_input, :prompt, :question_label
      attr_accessor :job_id

      def initialize(attempt:, job_id:, prompt:, question_label:, grading_suggestion_input:)
        @attempt = attempt
        @prompt = prompt
        @question_label = question_label
        @grading_suggestion_input = grading_suggestion_input
        self.job_id = job_id
      end

      def generate
        return unless is_open_ended_question? && attempt.results&.has_response?(question.label)

        QuestionGenerator.new(
          attempt:,
          grading_suggestion_input:,
          job_id:,
          prompt:,
          question_label:,
          student_submission: response
        ).generate
      end

      private def response
        return @response if defined? @response

        @response = attempt.results&.response(question.label)
      end

      private def question
        @question ||= content_object.questions.detect do |question|
          question.label == question_label
        end
      end

      private def is_open_ended_question?
        question.is_a?(MaestroActivityEngine::ActivityContent::OpenEnded::Item)
      end

      private def content_object
        activity.content_object
      end

      private def activity
        attempt.activity
      end
    end
  end
end
