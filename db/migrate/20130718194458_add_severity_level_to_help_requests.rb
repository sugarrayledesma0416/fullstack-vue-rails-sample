class AddSeverityLevelToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_requests, :severity_level, :integer, :default => 2
  end

  def self.down
    remove_column :help_requests, :severity_level
  end
end
