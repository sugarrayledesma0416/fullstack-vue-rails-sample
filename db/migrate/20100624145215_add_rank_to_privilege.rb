class AddRankToPrivilege < ActiveRecord::Migration[4.2]
  def self.up
    add_column :privileges, :rank, :integer, :default => 10
  end

  def self.down
    remove_column :privileges, :rank
  end
end
