class ChangeAIGradingSuggestionsAttemptIdToBigint < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column :ai_grading_suggestions, :attempt_id, :bigint
    end
  end
end
