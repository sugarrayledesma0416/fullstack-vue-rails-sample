class AddProgramIdToCartridgeCourseContextDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :cartridge_course_context_details, :program_id, :integer
  end
end
