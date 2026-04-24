class CreateInstitutionAdminHiddenCourses < ActiveRecord::Migration[5.2]
  def change
    create_table :institution_admin_hidden_courses do |t|
      t.integer :user_id
      t.integer :program_id
      t.integer :course_id

      t.timestamps

      t.index %i[user_id program_id course_id],
              name: 'idx_hidden_courses__user_id__program_id__course_id',
              unique: true
    end
  end
end
