class RenameUserLoginToUsername < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :users, :login, :username
  end

  def self.down
    rename_column :users, :username, :login
  end
end
