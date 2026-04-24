class AddEditedToAIGradingSuggestions < ActiveRecord::Migration[6.1]
  def change
    add_column(
      :ai_grading_suggestions,
      :edited,
      :boolean,
      default: false
    )
  end
end
