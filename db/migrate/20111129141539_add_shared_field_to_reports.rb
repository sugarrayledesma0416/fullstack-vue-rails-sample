class AddSharedFieldToReports < ActiveRecord::Migration[4.2]
  def self.up
    add_column :reports, :instructor_shared, :boolean, :default => false  
  end

  def self.down
    remove_column :reports, :instructor_shared
  end
end
