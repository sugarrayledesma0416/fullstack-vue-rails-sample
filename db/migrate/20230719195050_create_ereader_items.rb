class CreateEreaderItems < ActiveRecord::Migration[6.1]
  def change
    create_table :ereader_items do |t|
      t.string :guid, null: false
      t.string :title, null: false
      t.string :page_section, null: false
      t.string :descriptor
      t.integer :page_number, null: false
      t.references :concept, null: false
      t.timestamps
    end
  end
end
