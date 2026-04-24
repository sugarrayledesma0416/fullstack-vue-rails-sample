class CreateChatClickLogs < ActiveRecord::Migration[4.2]
  def self.up
    create_table :chat_click_logs do |t|
      t.string :source_tag
      t.string :username
      t.string :ip
      t.string :os
      t.string :browser
      t.string :url
      t.timestamps
    end
  end

  def self.down
    drop_table :chat_click_logs
  end
end
