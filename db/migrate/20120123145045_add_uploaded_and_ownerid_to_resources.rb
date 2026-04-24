class AddUploadedAndOwneridToResources < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :uploaded, :boolean, :default => false  
    add_column :resources, :owner_id, :integer, :null => true
  end

  def self.down
    remove_column :resources, :uploaded
    remove_column :resources, :owner_id
  end
end
