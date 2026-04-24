class AddActiveForInstructorGradingToAIGradingSuggestionPrompts < ActiveRecord::Migration[6.1]
  def change
    add_column(
      :ai_grading_suggestion_prompts,
      :active_for_instructor_grading,
      :boolean,
      default: false
    )
  end
end
