class AddRankToScreencast < ActiveRecord::Migration[4.2]
  def self.up
    add_column :screencasts, :rank, :integer
  end

  def self.down
    remove_column :screencasts, :rank
  end
end
