class AddCategoryNameToAsset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :category_name, :string
  end

  def self.down
    remove_column :assets, :category_name
  end
end
