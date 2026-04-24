class AddTocLocationToUnit < ActiveRecord::Migration[4.2]
  def self.up
    add_column :units, :toc_location, :integer
  end

  def self.down
    remove_column :units, :toc_location
  end
end
