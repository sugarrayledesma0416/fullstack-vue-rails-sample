class AddChatLevelToCourses < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :courses, :chat_enabled
    add_column :courses, :chat_level, :string, :default => 'partner_chat'
  end

  def self.down
    add_column :courses, :chat_enabled, :boolean, :default => false
    remove_column :courses, :chat_level
  end
end
