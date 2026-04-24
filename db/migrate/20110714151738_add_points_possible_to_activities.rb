class AddPointsPossibleToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :points_possible, :integer
  end

  def self.down
    remove_column :activities, :points_possible
  end
end
