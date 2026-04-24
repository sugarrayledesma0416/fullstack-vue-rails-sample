class CreateSiteLicensePackage < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :site_licenses_packages do |t|
      t.integer   :site_license_id
      t.integer   :package_id
      t.date      :start_date
      t.integer   :seats
      t.integer   :years

      t.timestamps
    end
  end

  def self.down
    drop_table :site_licenses_packages
  end
end
