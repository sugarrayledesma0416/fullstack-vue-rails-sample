class AddDefaultToAssignmentRank < ActiveRecord::Migration[4.2]
  def self.up
    change_column :assignments, :rank, :integer, default: 0
  end

  def self.down
    change_column :assignments, :rank, :integer
  end
end
