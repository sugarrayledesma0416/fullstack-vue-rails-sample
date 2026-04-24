class AddIsDeactivatedAndCommentsToSiteLicenses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :site_licenses, :comments, :text
    add_column :site_licenses, :is_deactivated, :boolean , :default => false
  end

  def self.down
    remove_column :site_licenses, :is_deactivated
    remove_column :site_licenses, :comments
  end
end
