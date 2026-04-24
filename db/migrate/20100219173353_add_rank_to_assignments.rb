class AddRankToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :rank, :integer
  end

  def self.down
    remove_column :assignments, :rank
  end
end
