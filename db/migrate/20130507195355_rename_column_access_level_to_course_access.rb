class RenameColumnAccessLevelToCourseAccess < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :enrollments, :access_level, :course_access
  end

  def self.down
    rename_column :enrollments, :course_access, :access_level
  end
end
