class CreateCartridgeUserLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :cartridge_user_links do |t|
      t.integer :school_id
      t.integer :user_id
      t.boolean :contexts_owner, default: false, null: false
      t.string :external_user_id

      t.string :guid
      t.bigint :sync_token, default: 0
      t.string :request_id

      t.timestamps

      t.index :guid
      t.index :user_id, unique: true
    end
  end
end
