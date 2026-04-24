class AddProntoFieldsToUserAndSection < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :pronto_activated,    :boolean, null: false, default: false
    add_column :users, :pronto_activated_at, :datetime

    add_column :sections, :pronto_enabled,    :boolean, null: false, default: false
    add_column :sections, :pronto_enabled_at, :datetime
  end

  def self.down
    remove_column :users, :pronto_activated
    remove_column :users, :pronto_activated_at

    remove_column :sections, :pronto_enabled
    remove_column :sections, :pronto_enabled_at
  end
end
