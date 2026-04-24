class RemoveInstructorUrlAndStudentBoolean < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :tours, :student_url
    remove_column :tours, :instructor_url
    remove_column :tours, :student
    add_column :tours, :url, :string 
  end

  def self.down
  end
end
