class AddCanIncludeSupersiteMaterialsToCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :categories, :can_include_supersite_materials, :boolean, :default => true
  end

  def self.down
    remove_column :categories, :can_include_supersite_materials
  end
end
