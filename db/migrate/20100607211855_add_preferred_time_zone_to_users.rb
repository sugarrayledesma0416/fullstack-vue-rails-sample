class AddPreferredTimeZoneToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :preferred_time_zone, :string 
  end

  def self.down
    remove_column :users, :preferred_time_zone
  end
end
