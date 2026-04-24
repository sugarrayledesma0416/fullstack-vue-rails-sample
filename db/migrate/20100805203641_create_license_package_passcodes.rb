class CreateLicensePackagePasscodes < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :license_package_passcodes do |t|
      t.integer   :license_package_id
      t.integer   :passcode_id
      t.integer   :passcode_type
    end
  end

  def self.down
    drop_table :license_package_passcodes
  end
end
