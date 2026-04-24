class AddStudentVisibilityToInstructorResourceSettings < ActiveRecord::Migration[4.2]
  def self.up
    add_column :instructor_resource_settings, :student_visibility, :string, :null => true
  end

  def self.down
    remove_column :instructor_resource_settings, :student_visibility
  end
end
