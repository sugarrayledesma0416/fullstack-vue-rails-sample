class AddDescriptionToResources < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :description, :string
  end

  def self.down
    remove_column :resources, :description
  end
end
