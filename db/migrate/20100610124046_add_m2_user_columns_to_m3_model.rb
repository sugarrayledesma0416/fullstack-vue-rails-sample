class AddM2UserColumnsToM3Model < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :slx_contact_id, :string, :limit => 16
    add_column :users, :is_fake, :boolean
    add_column :users, :display_email, :boolean, :default=>false
    add_column :users, :is_archived, :boolean, :default=>false
  end

  def self.down
    remove_column :users, :slx_contact_id 
    remove_column :users, :is_fake
    remove_column :users, :display_email
    remove_column :users, :is_archived
  end
end
