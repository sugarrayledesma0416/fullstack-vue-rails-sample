class AddTokenToPartnerChatRecordings < ActiveRecord::Migration[4.2]
  def self.up
    add_column :partner_chat_recordings, :token, :string
  end

  def self.down
    remove_column :partner_chat_recordings, :token
  end
end
