class AddIsSharedToSharedLibraryActivity < ActiveRecord::Migration[5.2]
  def up
    add_column :shared_library_activities, :is_shared, :boolean
    change_column_default :shared_library_activities, :is_shared, false
  end

  def down
    remove_column :shared_library_activities, :is_shared
  end
end
