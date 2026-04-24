class AddCurrentFlagToAssignment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :current, :boolean, :default => 0
  end

  def self.down
    remove_column :assignments, :current
  end
end
