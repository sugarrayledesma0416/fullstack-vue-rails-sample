class RemoveActivityIdFromAssignments < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :assignments, :activity_id
  end

  def self.down
    add_column :assignments, :activity_id, :integer
  end
end
