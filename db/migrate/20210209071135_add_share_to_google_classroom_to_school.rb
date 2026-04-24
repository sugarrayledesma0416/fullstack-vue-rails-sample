class AddShareToGoogleClassroomToSchool < ActiveRecord::Migration[5.2]
  def up
    add_column :schools, :share_to_google_classroom, :boolean
    add_column :schools, :share_to_google_classroom_last_updated_at, :datetime
    change_column_default :schools, :share_to_google_classroom, false
    change_column_default :schools, :share_to_google_classroom_last_updated_at, -> { 'CURRENT_TIMESTAMP' }
  end

  def down
    remove_column :schools, :share_to_google_classroom
    remove_column :schools, :share_to_google_classroom_last_updated_at
  end
end
