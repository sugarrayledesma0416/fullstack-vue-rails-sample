class AddInactiveToEnrollment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :enrollments, :inactive, :boolean, :default => 0
  end

  def self.down
    remove_column :enrollments, :inactive
  end
end
