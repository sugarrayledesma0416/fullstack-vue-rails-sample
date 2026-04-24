class AddExpirationDateToUserPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    add_column :user_privileges, :expiration_date, :date
  end

  def self.down
    remove_column :user_privileges, :expiration_date
  end
end
