class AddDownloadableToAsset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :downloadable, :boolean, :default => 1
  end

  def self.down
    remove_column :assets, :downloadable
  end
end
