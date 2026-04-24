class AddVhlStudentResourceToResources < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :vhl_student_resource, :boolean, :default => false
  end

  def self.down
    remove_column :resources, :vhl_student_resource
  end
end
