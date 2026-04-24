class CreateMaintanenceMessagesTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :maintanence_messages do |t|
      t.text      :message 
      t.datetime  :start 
      t.datetime  :end
      t.boolean   :published , :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :maintanence_messages
  end
end
