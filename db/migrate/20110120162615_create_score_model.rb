class CreateScoreModel < ActiveRecord::Migration[4.2]
  def self.up
    create_table :scores do |score|
      score.integer :user_id
      score.integer :activity_id
      score.integer :section_id
      score.integer :points_possible
      score.integer :points_earned
      score.timestamps
    end
    add_index :scores, [:user_id, :activity_id]
  end

  def self.down
    drop_table :scores
  end
end
