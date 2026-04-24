class AddUniqueIndexToGradingSets < ActiveRecord::Migration[4.2]
  def self.up
    add_index :grading_sets, [:program_id, :user_id, :activity_id], :unique => true
  end

  def self.down
    remove_index :grading_sets, [:program_id, :user_id, :activity_id]
  end
end
