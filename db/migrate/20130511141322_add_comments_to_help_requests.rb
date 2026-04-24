class AddCommentsToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_requests, :comment, :text
  end

  def self.down
    remove_column :help_requests, :comment
  end
end
