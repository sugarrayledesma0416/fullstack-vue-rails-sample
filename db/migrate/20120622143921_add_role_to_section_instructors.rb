class AddRoleToSectionInstructors < ActiveRecord::Migration[4.2]
  def self.up
    add_column :section_instructors, :role, :string
  end

  def self.down
    remove_column :section_instructors, :role
  end
end
