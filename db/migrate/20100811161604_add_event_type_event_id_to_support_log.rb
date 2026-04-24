class AddEventTypeEventIdToSupportLog < ActiveRecord::Migration[4.2]
  def self.up
    add_column :support_logs, :event_type, :string
    add_column :support_logs, :event_id, :integer
  end

  def self.down
    remove_column :support_logs, :event_id
    remove_column :support_logs, :event_type
  end
end
