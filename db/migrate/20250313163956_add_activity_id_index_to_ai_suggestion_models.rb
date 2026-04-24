class AddActivityIdIndexToAISuggestionModels < ActiveRecord::Migration[6.1]
  def up
    add_index :ai_grading_suggestions, :activity_id
    add_index :ai_overall_comments, :activity_id
  end

  def down
    remove_index :ai_grading_suggestions, :activity_id
    remove_index :ai_overall_comments, :activity_id
  end
end
