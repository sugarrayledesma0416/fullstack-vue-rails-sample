class AddNamePathToAsset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :name, :string
    add_column :assets, :path, :string
  end

  def self.down
    remove_column :assets, :path
    remove_column :assets, :name
  end
end
