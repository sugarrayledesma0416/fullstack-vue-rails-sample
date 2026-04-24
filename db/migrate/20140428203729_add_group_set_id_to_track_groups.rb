class AddGroupSetIdToTrackGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :track_groups, :group_set_id, :integer
  end

  def down
    remove_column :track_groups, :group_set_id
  end
end
