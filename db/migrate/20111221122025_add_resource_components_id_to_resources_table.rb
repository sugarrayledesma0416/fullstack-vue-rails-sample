class AddResourceComponentsIdToResourcesTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :resource_components_id, :integer
  end

  def self.down
    add_column :resources, :resource_components_id, :integer
  end
end
