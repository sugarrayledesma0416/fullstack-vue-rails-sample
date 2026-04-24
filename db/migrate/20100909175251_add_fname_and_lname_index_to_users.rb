class AddFnameAndLnameIndexToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_index :users, :first_name
    add_index :users, :last_name
  end

  def self.down
    remove_index :users, :first_name
    remove_index :users, :last_name
  end
end
