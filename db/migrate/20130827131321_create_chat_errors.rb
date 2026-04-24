class CreateChatErrors < ActiveRecord::Migration[4.2]
  def self.up
    create_table :chat_errors do |t|
      t.references :user
      t.references :activity
      t.string :error
      t.string :flash_version
      t.string :browser
      t.string :browser_version
      t.string :platform
      t.timestamps
    end
  end

  def self.down
    drop_table :chat_errors
  end
end
