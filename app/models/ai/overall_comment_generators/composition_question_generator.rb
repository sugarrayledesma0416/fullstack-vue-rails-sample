module AI
  module OverallCommentGenerators
    class CompositionQuestionGenerator
      attr_reader :attempt, :grading_suggestion_input, :prompt, :question_label

      def initialize(attempt:, grading_suggestion_input:, prompt:, question_label:)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        @prompt = prompt
        @question_label = question_label
      end

      def generate
        return unless is_composition_question? && attempt.results&.has_response?(question.label)

        QuestionGenerator.new(
          attempt:,
          grading_suggestion_input:,
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

      private def is_composition_question?
        question.is_a?(MaestroActivityEngine::ActivityContent::Composition::Item)
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
