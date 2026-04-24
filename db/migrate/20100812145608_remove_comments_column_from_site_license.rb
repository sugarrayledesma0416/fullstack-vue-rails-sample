class RemoveCommentsColumnFromSiteLicense < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :site_licenses, :comments
  end

  def self.down
    add_column :site_licenses, :comments, :text
  end
end
