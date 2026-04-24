class CreateInstructorResourceSettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :instructor_resource_settings do |t|
      t.integer    :resource_id
      t.integer    :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table  :instructor_resource_settings
  end
end
