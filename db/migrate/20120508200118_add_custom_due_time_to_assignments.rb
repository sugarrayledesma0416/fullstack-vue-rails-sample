class AddCustomDueTimeToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :custom_due_time, :time
  end

  def self.down
    remove_column :assignments, :custom_due_time
  end
end
