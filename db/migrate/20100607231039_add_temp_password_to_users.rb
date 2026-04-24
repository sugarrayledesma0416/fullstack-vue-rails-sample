class AddTempPasswordToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :is_temp_password, :boolean, :default => false
  end

  def self.down
    remove_column :users, :is_temp_password
  end
end
