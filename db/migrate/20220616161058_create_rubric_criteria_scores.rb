class CreateRubricCriteriaScores < ActiveRecord::Migration[5.2]
  def up
    create_table :rubric_criteria_scores do |t|
      t.integer :attempt_id
      t.text :criteria_score_json

      t.timestamps
    end

    add_index :rubric_criteria_scores, :attempt_id, name: 'idx_rubric_criteria_score_attempt_id'
  end

  def down
    remove_index :rubric_criteria_scores, name: 'idx_rubric_criteria_score_attempt_id'
    drop_table :rubric_criteria_scores
  end
end
