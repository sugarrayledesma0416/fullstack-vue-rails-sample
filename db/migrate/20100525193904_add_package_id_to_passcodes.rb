class AddPackageIdToPasscodes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :passcodes, :package_id, :integer
  end

  def self.down
    remove_column :passcodes, :package_id
  end
end
