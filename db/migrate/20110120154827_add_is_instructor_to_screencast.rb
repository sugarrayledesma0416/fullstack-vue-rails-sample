class AddIsInstructorToScreencast < ActiveRecord::Migration[4.2]
  def self.up
    add_column :screencasts, :is_instructor, :boolean
  end

  def self.down
    remove_column :screencasts, :is_instructor
  end
end
