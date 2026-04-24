class RemoveRevisionIdToSharedLibraryActivity < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :shared_library_activities, :instructor_revision_id, :integer }
  end
end
