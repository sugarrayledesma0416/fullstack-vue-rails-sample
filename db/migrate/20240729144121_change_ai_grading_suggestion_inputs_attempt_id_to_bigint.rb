class ChangeAIGradingSuggestionInputsAttemptIdToBigint < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column :ai_grading_suggestion_inputs, :attempt_id, :bigint
    end
  end
end
