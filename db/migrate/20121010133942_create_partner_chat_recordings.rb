class CreatePartnerChatRecordings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :partner_chat_recordings do |t|
      t.integer  :user_id, :null => false, :default => 0
      t.integer  :partner_id, :null => false, :default => 0
      t.string   :recording_path, :null => false
      t.integer  :activity_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :partner_chat_recordings
  end
end
