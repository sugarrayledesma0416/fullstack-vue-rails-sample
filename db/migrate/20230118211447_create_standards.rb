class CreateStandards < ActiveRecord::Migration[6.1]
  def change
    create_table :standards do |t|
      t.string :vendor_guid, null: false
      t.string :vendor_standard_set_guid
      t.string :name
      t.text :description
      t.string :label
      t.string :number
      t.json :additional_info
      t.timestamps
    end

    add_index :standards, :vendor_guid
    add_index :standards, :vendor_standard_set_guid
  end
end
