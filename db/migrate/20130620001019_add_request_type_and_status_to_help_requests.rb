class AddRequestTypeAndStatusToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :help_requests, :help_type, :helpable_item_type
    rename_column :help_requests, :help_item_requested, :helpable_item_id
    add_column :help_requests, :request_type, :string, :null => false
    add_column :help_requests, :status, :string, :null => false, :default => 'submitted'
  end

  def self.down
    drop_column :help_requests, :status
    drop_column :help_requests, :request_type
    rename_column :help_requests, :helpable_item_id, :help_item_requested
    rename_column :help_requests, :helpable_item_type, :help_type
  end
end
