class AddTimeLimitToAssignments < ActiveRecord::Migration[4.2]
  def up
    add_column :assignments, :time_limit, :integer, :default => 0, :null => false
  end

  def down
    remove_column :assignments, :time_limit
  end
end
