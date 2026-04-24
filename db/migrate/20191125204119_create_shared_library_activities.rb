class CreateSharedLibraryActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :shared_library_activities do |t|
      t.integer :activity_id
      t.integer :school_id
      t.index :school_id
      t.index %i[activity_id school_id],
              name: 'idx_shared_library_activities__activity_id__school_id'

      t.timestamps null: false
    end
  end
end
