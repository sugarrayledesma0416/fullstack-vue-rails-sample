class MakeAuthlogicRelatedColumnsNullableOnUser < ActiveRecord::Migration[4.2]
  def up
    remove_index :users, :perishable_token
    remove_index :users, :persistence_token
    remove_index :users, :single_access_token

    change_column :users, :crypted_password, :string, null: true
    change_column :users, :password_salt, :string, null: true
    change_column :users, :persistence_token, :string, null: true
    change_column :users, :single_access_token, :string, null: true
    change_column :users, :login_count, :integer, null: true
    change_column :users, :perishable_token, :string, null: true
    change_column :users, :failed_login_count, :integer, null: true

  end

  def down
    change_column :users, :crypted_password, :string, null: false
    change_column :users, :password_salt, :string, null: false
    change_column :users, :persistence_token, :string, null: false
    change_column :users, :single_access_token, :string, null: false
    change_column :users, :login_count, :integer, null: false
    change_column :users, :perishable_token, :string, null: false
    change_column :users, :failed_login_count, :integer, null: false

    add_index :users, :perishable_token
    add_index :users, :persistence_token
    add_index :users, :single_access_token
  end
end

