class RemoveCountFromSiteLicenses < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :site_licenses, :count
  end

  def self.down
    add_column :site_licenses, :count, :integer
  end
end
