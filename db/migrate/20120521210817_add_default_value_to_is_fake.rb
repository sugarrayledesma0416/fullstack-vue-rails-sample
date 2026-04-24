class AddDefaultValueToIsFake < ActiveRecord::Migration[4.2]
  def self.up
    change_column :users, :is_fake, :boolean, default: 0, null: false
  end

  def self.down
    change_column :users, :is_fake, :boolean, default: nil, null: true
  end
end
