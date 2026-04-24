class AddLicenseGroupToActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :license_group_id, :integer
  end

  def self.down
    remove_column :activities, :license_group_id
  end
end
