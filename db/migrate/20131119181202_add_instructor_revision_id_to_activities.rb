class AddInstructorRevisionIdToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :instructor_revision_id, :integer
  end

  def self.down
    remove_column :activities, :instructor_revision_id
  end
end
