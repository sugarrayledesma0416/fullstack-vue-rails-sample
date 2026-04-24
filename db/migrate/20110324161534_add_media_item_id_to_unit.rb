class AddMediaItemIdToUnit < ActiveRecord::Migration[4.2]
  def self.up
    add_column :units, :media_item_id, :integer
  end

  def self.down
    remove_column :units, :media_item_id
  end
end
