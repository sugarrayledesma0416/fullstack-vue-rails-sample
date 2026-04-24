class AddPartnerPracticeToPartnerChatRecording < ActiveRecord::Migration[4.2]
  def self.up
    add_column :partner_chat_recordings, :partner_practice, :boolean, :default => false
  end

  def self.down
    remove_column :partner_chat_recordings, :partner_practice
  end
end
