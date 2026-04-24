class ChangeScoresActivityIdIndexToScorableId < ActiveRecord::Migration[4.2]
  def self.up
    remove_index :scores, [:user_id, :activity_id]
    add_index :scores, [:user_id, :scorable_id, :scorable_type]
  end

  def self.down
    add_index :scores, [:user_id, :activity_id]
    remove_index :scores, [:user_id, :scorable_id, :scorable_type]
  end
end
