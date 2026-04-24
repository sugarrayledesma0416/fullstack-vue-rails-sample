class AddActiveToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :active, :boolean , :default => true 
  end

  def self.down
    remove_column :users, :active
  end
end
