class AddSubcomponentNameToResourcesRemoveParentIdFromResourceComponents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :subcomponent_name, :string
    remove_column :resource_components, :parent_id
  end

  def self.down
    remove_column :resources, :subcomponent_name
    add_column :resource_components, :parent_id, :integer 
  end
end
