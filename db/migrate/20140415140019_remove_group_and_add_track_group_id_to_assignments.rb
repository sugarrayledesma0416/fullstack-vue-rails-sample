class RemoveGroupAndAddTrackGroupIdToAssignments < ActiveRecord::Migration[4.2]
  def up
    remove_column :assignments ,:group
    add_column :assignments, :track_group_id, :integer
  end

  def down
    remove_column :assignments, :track_group_id
    add_column :assignments, :group, :string
  end
end
