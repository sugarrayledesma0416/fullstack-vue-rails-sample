class AddPointsPossibleToExternalActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :external_activities, :points_possible, :integer
  end

  def self.down
    remove_column :external_activities, :points_possible
  end
end
