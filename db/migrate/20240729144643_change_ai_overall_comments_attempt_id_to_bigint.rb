class ChangeAIOverallCommentsAttemptIdToBigint < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column :ai_overall_comments, :attempt_id, :bigint
    end
  end
end
