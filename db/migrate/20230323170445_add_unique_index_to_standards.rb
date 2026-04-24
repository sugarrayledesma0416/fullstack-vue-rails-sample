class AddUniqueIndexToStandards < ActiveRecord::Migration[6.1]
  def change
    remove_index :standards, :vendor_guid
    add_index :standards, :vendor_guid, unique: true
  end
end
