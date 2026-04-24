class AddUniquenessToVendorGuidIndexStandardAssets < ActiveRecord::Migration[6.1]
  def up
    remove_index :standard_assets, :vendor_guid
    add_index  :standard_assets, :vendor_guid, unique: true
  end

  def down
    remove_index :standard_assets, :vendor_guid, unqiue: true
    add_index :standard_assets, :vendor_guid
  end
end
