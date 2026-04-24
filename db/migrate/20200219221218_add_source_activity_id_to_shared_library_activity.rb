class AddSourceActivityIdToSharedLibraryActivity < ActiveRecord::Migration[5.2]
  def change
    add_column :shared_library_activities, :source_activity_id, :integer
  end
end
