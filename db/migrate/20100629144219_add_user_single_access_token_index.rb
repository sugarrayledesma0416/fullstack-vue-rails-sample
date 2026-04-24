class AddUserSingleAccessTokenIndex < ActiveRecord::Migration[4.2]
  def self.up
    add_index :users, :single_access_token
  end

  def self.down
    remove_index :users, :single_access_token
  end
end
