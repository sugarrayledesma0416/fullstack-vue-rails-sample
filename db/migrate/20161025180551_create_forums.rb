class CreateForums < ActiveRecord::Migration[4.2]
  def change
    create_table :forums do |table|
      table.integer :section_id, null: false
      table.integer :instructor_id, null: false
      table.string :name, null: false
      table.text :directions

      table.timestamps
    end

    add_index :forums, :section_id, name: 'by_section'
  end
end
