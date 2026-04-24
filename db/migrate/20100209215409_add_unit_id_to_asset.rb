class AddUnitIdToAsset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :unit_id, :integer
  end

  def self.down
    remove_column :assets, :unit_id
  end
end
