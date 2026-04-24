class AddSchoolIdToCourses < ActiveRecord::Migration[4.2]
  
  # accidentally named this wrong.  fixed in subsequent migration
  def self.up
    add_column :courses, :course_id, :integer
  end

  def self.down
    remove_column :courses, :course_id
  end
end
