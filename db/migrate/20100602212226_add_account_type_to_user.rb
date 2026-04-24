class AddAccountTypeToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :account_type, :string, null: false, default: 'Student'
  end

  def self.down
    remove_column :users, :account_type
  end
end
