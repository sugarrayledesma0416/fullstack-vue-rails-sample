class AddRegistrationOpenFlagToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :is_registration_window_open, :boolean, :default => true
    sql = 'UPDATE users SET is_registration_window_open = 0;'
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :users, :is_registration_window_open
  end
end
