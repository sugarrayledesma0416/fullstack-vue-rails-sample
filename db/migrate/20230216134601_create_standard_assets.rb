class CreateStandardAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :standard_assets do |t|
      t.string :vendor_guid, null: false
      t.integer :reference_id, null: false
      t.string :reference_type, null:false
      t.boolean :m3_publish_status
      t.datetime :date_alignments_modified_utc
      t.timestamps
    end

    add_index :standard_assets, :vendor_guid
    add_index :standard_assets, :reference_id
    add_index :standard_assets, :reference_type
  end
end
