class RemoveActivityIdFromScores < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :scores, :activity_id
  end

  def self.down
    add_column :scores, :activity_id, :integer
  end
end
