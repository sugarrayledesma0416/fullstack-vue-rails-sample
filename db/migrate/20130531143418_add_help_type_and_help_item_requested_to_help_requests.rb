class AddHelpTypeAndHelpItemRequestedToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_requests, :help_type, :string, :default => nil
    add_column :help_requests, :help_item_requested, :string, :default => nil
  end

  def self.down
    remove_column :help_requests, :help_type
    remove_column :help_requests, :help_item_requested
  end
end
