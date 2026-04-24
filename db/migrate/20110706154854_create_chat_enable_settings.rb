class CreateChatEnableSettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :chat_enable_settings do |t|
      t.date :start_date
      t.date :end_date
      t.time :start_time
      t.time :end_time
      t.string :time_zone , :default => "Eastern Time (US & Canada)"
      t.integer :days_of_week, :default => 62 
      t.boolean :enabled , :default => true
    end
  end

  def self.down
    drop_table :chat_enable_settings 
  end
end
