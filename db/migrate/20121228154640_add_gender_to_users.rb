class AddGenderToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :gender, :string
  end

  def self.down
    remove_column :users, :gender
  end
end
