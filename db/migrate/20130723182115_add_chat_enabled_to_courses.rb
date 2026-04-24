class AddChatEnabledToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :chat_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :courses, :chat_enabled
  end
end
