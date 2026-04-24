class AddInstructorIdToActivities < ActiveRecord::Migration[4.2]
  def up
    add_column :activities, :instructor_id, :integer
  end

  def down
    remove_column :activities, :instructor_id
  end
end
