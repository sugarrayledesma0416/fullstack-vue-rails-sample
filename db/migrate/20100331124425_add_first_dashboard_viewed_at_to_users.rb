class AddFirstDashboardViewedAtToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :first_dashboard_viewed_at, :datetime
  end

  def self.down
    remove_column :users, :first_dashboard_viewed_at
  end
end
