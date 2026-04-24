class AddAssetPathToMediaItems < ActiveRecord::Migration[4.2]
  def self.up
    add_column :media_items, :asset_path, :string
  end

  def self.down
    remove_column :media_items, :asset_path
  end
end
