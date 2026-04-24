class CreateStandardSets < ActiveRecord::Migration[6.1]
  def change
    create_table :standard_sets do |t|
      t.string :vendor_guid, null: false
      t.string :issuer
      t.string :name
      t.integer :adopt_year
      t.string :state
      t.string :acronym
      t.text :description
      t.timestamps
    end

    add_index :standard_sets, :vendor_guid
  end
end
