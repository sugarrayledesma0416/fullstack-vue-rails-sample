module AI
  module LiveData
    class OverallCommentsForPromptGenerator
      attr_reader :prompt

      def initialize(prompt)
        @prompt = prompt
      end

      def generate
        AI::GradingSuggestionInput.joins(
          %(
            LEFT OUTER JOIN ai_overall_comments
              ON ai_overall_comments.grading_suggestion_input_id = ai_grading_suggestion_inputs.id
              AND ai_overall_comments.prompt_id = #{prompt.id}
          )
        ).where(ai_overall_comments: { id: nil }).find_each do |input|
          AI::OverallCommentGenerators::AsyncQuestionGenerator.new(
            attempt: input.attempt,
            prompt:,
            question_label: input.question_label,
            grading_suggestion_input: input
          ).generate
        end
      end
    end
  end
end
