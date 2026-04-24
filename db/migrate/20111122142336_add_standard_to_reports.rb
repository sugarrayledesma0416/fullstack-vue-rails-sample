class AddStandardToReports < ActiveRecord::Migration[4.2]
  def self.up
    add_column :reports, :standard, :boolean, :default => false  
  end

  def self.down
    remove_column :reports, :standard
  end
end
