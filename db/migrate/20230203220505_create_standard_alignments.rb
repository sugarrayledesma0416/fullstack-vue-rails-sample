class CreateStandardAlignments < ActiveRecord::Migration[6.1]
  def change
    create_table :standard_alignments do |t|
      t.integer :standard_asset_id, null: false
      t.string :vendor_asset_guid, null: false
      t.string :vendor_standard_guid, null: false
      t.string :alignment_status
      t.timestamps
    end
  end
end
