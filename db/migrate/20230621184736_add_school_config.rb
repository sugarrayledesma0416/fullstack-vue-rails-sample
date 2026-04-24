class AddSchoolConfig < ActiveRecord::Migration[6.1]
  def change
    create_table :school_configs do |t|
      t.integer :school_id
      t.boolean :chat_support_disabled, default: false, null: false
      t.string :guid
      t.bigint :sync_token, default: 0
      t.string :request_id

      t.timestamps
      t.index [:guid]
      t.index [:school_id], unique: true
    end
  end
end
