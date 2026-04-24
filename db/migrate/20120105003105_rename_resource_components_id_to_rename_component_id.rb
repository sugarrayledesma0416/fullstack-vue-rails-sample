class RenameResourceComponentsIdToRenameComponentId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :resources, :resource_components_id, :resource_component_id
  end

  def self.down
    rename_column :resources, :resource_component_id, :resource_components_id
  end
end
