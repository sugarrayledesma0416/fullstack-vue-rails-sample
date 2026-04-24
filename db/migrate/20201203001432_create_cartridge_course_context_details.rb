class CreateCartridgeCourseContextDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :cartridge_course_context_details do |t|
      t.string :lms_context_id, null: false
      t.index :lms_context_id
      t.string :launch_presentation_return_url
      t.string :lis_outcome_service_url
      t.references :course, index: false, null: false
      t.integer :section_id, null: false
      t.references :school, index: false, null: false

      t.timestamps

      t.index %i[lms_context_id school_id],
        unique: true,
        name: :index_cartridge_course_context_details_on_lms_context_id_school
    end
    add_index :cartridge_course_context_details, :section_id
  end
end
