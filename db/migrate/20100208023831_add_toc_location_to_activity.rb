class AddTocLocationToActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :toc_location, :integer
    add_column :activities, :unit_id, :integer
  end

  def self.down
    remove_column :activities, :toc_location
    remove_column :activities, :unit_id
  end
end
