class RenameCourseIdToSchoolId < ActiveRecord::Migration[4.2]
  
  # accidentally gave this the wrong name when column was created
  def self.up
    rename_column :courses, :course_id, :school_id
  end

  def self.down
    rename_column :courses, :school_id, :course_id    
  end
end
