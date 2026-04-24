class AddAccessLevelToEnrollment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :enrollments, :access_level, :boolean, :default => true
  end

  def self.down
    remove_column :enrollments, :access_level
  end
end
