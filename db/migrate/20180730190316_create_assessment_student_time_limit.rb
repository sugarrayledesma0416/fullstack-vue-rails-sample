class CreateAssessmentStudentTimeLimit < ActiveRecord::Migration[4.2]
  def up
    create_table :assessment_student_time_limits do |t|
      t.integer :user_id 
      t.integer :section_id 
      t.integer :activity_id 
      t.integer :time_limit 

      t.timestamps
    end
    add_index :assessment_student_time_limits, [:section_id, :activity_id, :user_id], name: 'by_section_activity_user_index', unique: true
  end

  def down
    drop_table :assessment_student_time_limits
  end
end
