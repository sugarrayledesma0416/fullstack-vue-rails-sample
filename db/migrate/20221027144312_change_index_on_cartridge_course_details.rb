class ChangeIndexOnCartridgeCourseDetails < ActiveRecord::Migration[5.2]
  def up
    remove_index :cartridge_course_context_details, name: :index_cartridge_course_context_details_on_lms_context_id_school

    add_index :cartridge_course_context_details,
              %i[lms_context_id school_id program_id],
              unique: true,
              name: :idx_cartridge_crs_context_details_on_lms_context_id_school_prog
  end

  def down
    remove_index :cartridge_course_context_details, name: :idx_cartridge_crs_context_details_on_lms_context_id_school_prog

    add_index :cartridge_course_context_details,
              %i[lms_context_id school_id],
              unique: true,
              name: :index_cartridge_course_context_details_on_lms_context_id_school
  end
end
