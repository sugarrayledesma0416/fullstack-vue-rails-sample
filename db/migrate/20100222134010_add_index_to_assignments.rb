class AddIndexToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_index :assignments, [:due_date, :rank], :name => 'due_date_rank'
  end

  def self.down
    remove_index :assignments, :due_date_rank
  end
end
