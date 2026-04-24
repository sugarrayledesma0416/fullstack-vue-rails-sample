class CreateCartridgeConsumers < ActiveRecord::Migration[5.2]
  def change
    create_table :cartridge_consumers do |t|
      t.string :name, null: false
      t.text :key, null: false
      t.text :secret, null: false
      t.integer :school_id

      t.string :guid
      t.bigint :sync_token, default: 0
      t.string :request_id
      t.timestamps

      t.index :guid
      t.index :school_id
    end
  end
end
