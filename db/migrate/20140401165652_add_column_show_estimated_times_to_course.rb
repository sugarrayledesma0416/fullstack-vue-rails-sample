class AddColumnShowEstimatedTimesToCourse < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :show_estimated_times, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :courses, :show_estimated_times
  end
end
