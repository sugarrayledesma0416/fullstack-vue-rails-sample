class AddAllowCopyToSharedLibraryActivity < ActiveRecord::Migration[5.2]
  def up
    add_column :shared_library_activities, :allow_copy, :boolean
    change_column_default :shared_library_activities, :allow_copy, :false
  end

  def down
    remove_column :shared_library_activities, :allow_copy
  end
end
