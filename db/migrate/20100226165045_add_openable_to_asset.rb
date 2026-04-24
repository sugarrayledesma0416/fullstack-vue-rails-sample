class AddOpenableToAsset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :openable, :boolean, :default => 0
  end

  def self.down
    remove_column :assets, :openable
  end
end
