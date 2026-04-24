class AddMediaIdToAssets < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :media_item_id, :integer
  end

  def self.down
    remove_column :assets, :media_item_id
  end
end
