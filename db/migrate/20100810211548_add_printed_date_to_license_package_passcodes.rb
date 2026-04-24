class AddPrintedDateToLicensePackagePasscodes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :license_package_passcodes, :printed_on, :date
  end

  def self.down
    remove_column :license_package_passcodes, :printed_on
  end
end
