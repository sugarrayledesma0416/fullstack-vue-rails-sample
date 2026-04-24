class AddIsArchivedToCartridgeCourseContextDetail < ActiveRecord::Migration[5.2]
  def change
    add_column :cartridge_course_context_details, :is_archived, :boolean
    change_column_default :cartridge_course_context_details, :is_archived, false
  end
end
