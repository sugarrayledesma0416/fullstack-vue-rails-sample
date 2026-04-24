class AddBitGravityBit < ActiveRecord::Migration[4.2]
  def self.up
    add_column :media_items, :cdn, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :media_items, :cdn
  end
end
