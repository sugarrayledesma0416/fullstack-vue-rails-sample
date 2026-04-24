class AddRankToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :rank, :integer
  end

  def self.down
    remove_column :activities, :rank
  end
end
