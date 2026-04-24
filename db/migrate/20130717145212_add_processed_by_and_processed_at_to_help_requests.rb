class AddProcessedByAndProcessedAtToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_requests, :processed_by, :integer
    add_column :help_requests, :processed_at, :datetime
  end

  def self.down
    remove_column :help_requests, :processed_by
    remove_column :help_requests, :processed_at
  end
end
