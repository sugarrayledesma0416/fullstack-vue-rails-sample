class RenameIsColumnsFromUsers < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :users, :is_fake, :fake
    rename_column :users, :is_archived, :archived
    rename_column :users, :is_temp_password, :temp_password
    rename_column :users, :is_registration_window_open, :registration_window_open
  end

  def self.down
    rename_column :users, :fake, :is_fake
    rename_column :users, :archived, :is_archived
    rename_column :users, :temp_password, :is_temp_password
    rename_column :users, :registration_window_open, :is_registration_window_open
  end
end
