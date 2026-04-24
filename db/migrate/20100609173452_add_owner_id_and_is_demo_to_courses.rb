class AddOwnerIdAndIsDemoToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :owner_id, :integer
    add_column :courses, :is_demo, :boolean, :default => false
  end

  def self.down
    remove_column :courses, :is_demo
    remove_column :courses, :owner_id
  end
end
