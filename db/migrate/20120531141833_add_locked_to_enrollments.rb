class AddLockedToEnrollments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :enrollments, :locked, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :enrollments, :locked
  end
end
