class ChangeAISuggestionRatingDetailsAttemptIdToBigint < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column :ai_suggestion_rating_details, :attempt_id, :bigint
    end
  end
end
