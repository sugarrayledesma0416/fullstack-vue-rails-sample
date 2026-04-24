class AddObjectiveToTrackGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :track_groups, :objective, :string
  end

  def down
    remove_column :track_groups, :objective
  end
end
