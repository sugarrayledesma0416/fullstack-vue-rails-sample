class CreateGroupChatRecordings < ActiveRecord::Migration[5.2]
  def self.up
    create_table :group_chat_recordings do |t|
      t.references :user, index: false, null: false
      t.json :participants, null: false
      t.string :recording_path, null: false
      t.references :activity, index: false, null: false
      t.string :token, null: false
      t.boolean :partner_practice, null: false, default: false
      t.json :practicing_users, null: false # default value is set in the model.

      t.timestamps
    end
    add_index :group_chat_recordings, :activity_id,
      name: :idx_group_chat_recordings_activity_id
  end

  def self.down
    remove_index :group_chat_recordings, name: :idx_group_chat_recordings_activity_id
    drop_table :group_chat_recordings
  end
end
