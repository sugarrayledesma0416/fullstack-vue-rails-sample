module AI
  module LiveData
    class GradingSuggestionsForPromptGenerator
      attr_reader :prompt

      def initialize(prompt)
        @prompt = prompt
      end

      def generate
        AI::GradingSuggestionInput.joins(
          %(
            LEFT OUTER JOIN ai_grading_suggestions
              ON ai_grading_suggestions.grading_suggestion_input_id = ai_grading_suggestion_inputs.id
              AND ai_grading_suggestions.prompt_id = #{prompt.id}
          )
        ).where(ai_grading_suggestions: { id: nil }).find_each do |input|
          AI::GradingSuggestionGenerators::AsyncQuestionGenerator.new(
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
