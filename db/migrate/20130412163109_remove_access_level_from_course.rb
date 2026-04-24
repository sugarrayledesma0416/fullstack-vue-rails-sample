class RemoveAccessLevelFromCourse < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :courses, :access_level
  end

  def self.down
    add_column :courses, :access_level, :integer
  end
end
