class AddAccountTypeToHomepageContents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :homepage_contents, :account_type, :string, null: false, default: 'All'
  end

  def self.down
    remove_column :homepage_contents, :account_type
  end
end
