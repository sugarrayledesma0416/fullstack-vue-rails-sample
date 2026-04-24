class AddInstructorRevisionIdToSharedLibraryActivity < ActiveRecord::Migration[5.2]
  def change
    add_column :shared_library_activities, :instructor_revision_id, :integer
  end
end
