class AddSalesRepIdToSiteLicenses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :site_licenses, :sales_rep_id, :integer
  end

  def self.down
    remove_column :site_licenses, :sales_rep_id
  end
end
