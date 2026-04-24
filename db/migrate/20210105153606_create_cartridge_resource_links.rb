class CreateCartridgeResourceLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :cartridge_resource_links do |t|
      t.integer :resource_id, null:false
      t.string :resource_type, null:false
      t.string :resource_link_id, null:false
      t.integer :program_id, null:false

      t.timestamps

      t.index :resource_link_id, unique: true
      t.index %i[resource_id resource_type],
              name: 'index_cartridge_resource_links_on_resource_id_and_resource_type',
              unique: true
      t.index :program_id
    end
  end
end
