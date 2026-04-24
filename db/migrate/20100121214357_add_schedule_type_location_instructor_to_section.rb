class AddScheduleTypeLocationInstructorToSection < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :schedule, :string
    add_column :sections, :setting, :string
    add_column :sections, :instructor_id, :integer
    add_column :sections, :location, :string
  end

  def self.down
    remove_column :sections, :location
    remove_column :sections, :instructor_id
    remove_column :sections, :setting
    remove_column :sections, :schedule
  end
end
