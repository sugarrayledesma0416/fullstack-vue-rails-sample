class AddIndexToAttemptsForDashboard < ActiveRecord::Migration[4.2]
  def self.up
    add_index :attempts, [:user_id,:activity_id], :name => 'by_user_and_activity'
  end

  def self.down
    remove_index :attempts, :name => :by_user_and_activity
  end
end
