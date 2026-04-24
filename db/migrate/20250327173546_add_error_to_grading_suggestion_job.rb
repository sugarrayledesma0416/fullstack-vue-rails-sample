class AddErrorToGradingSuggestionJob < ActiveRecord::Migration[6.1]
  def up
    add_column :ai_grading_suggestion_jobs, :error, :string
  end

  def down
    remove_column :ai_grading_suggestion_jobs, :error
  end
end
