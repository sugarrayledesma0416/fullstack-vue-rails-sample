class RemoveCanIncludeSupersiteMaterialsFromCategories < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :categories, :can_include_supersite_materials
  end

  def self.down
    add_column :categories, :can_include_supersite_materials, :boolean, :default => true
  end
end
