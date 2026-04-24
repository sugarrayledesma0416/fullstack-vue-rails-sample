class AddOpenToStudentsToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :open_to_students, :boolean, default: true
  end

  def self.down
    remove_column :sections, :open_to_students
  end
end
