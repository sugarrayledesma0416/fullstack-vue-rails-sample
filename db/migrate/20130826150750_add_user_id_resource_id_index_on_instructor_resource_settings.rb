class AddUserIdResourceIdIndexOnInstructorResourceSettings < ActiveRecord::Migration[4.2]
  def self.up
    add_index :instructor_resource_settings, [:user_id, :resource_id], :name => 'by_user_and_resource'
  end

  def self.down
    remove_index :instructor_resource_settings, 'by_user_and_resource'
  end
end
