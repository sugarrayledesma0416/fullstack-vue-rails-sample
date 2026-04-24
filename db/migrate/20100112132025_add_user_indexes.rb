class AddUserIndexes < ActiveRecord::Migration[4.2]
  def self.up
    add_index :users, :perishable_token
    add_index :users, :email
  end

  def self.down
    remove_index :users, :perishable_token
    remove_index :users, :email
  end
end
