class AddProtectedtoResources < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :protected, :boolean, :default => false  
  end

  def self.down
    remove_column :resources, :protected
  end
end
