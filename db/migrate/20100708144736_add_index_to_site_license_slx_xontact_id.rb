class AddIndexToSiteLicenseSlxXontactId < ActiveRecord::Migration[4.2]
  def self.up
    add_index :site_licenses, :slx_contact_id
  end

  def self.down
    remove_index :site_licenses, :slx_contact_id
  end
end
