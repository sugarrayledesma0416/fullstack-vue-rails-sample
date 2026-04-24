class RenameColumnCourseAccessToSufficientAccess < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :enrollments, :course_access, :sufficient_access
  end

  def self.down
    rename_column :enrollments, :sufficient_access, :course_access
  end
end
