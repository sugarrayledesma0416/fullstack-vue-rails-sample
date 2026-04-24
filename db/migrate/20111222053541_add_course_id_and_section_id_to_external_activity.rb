class AddCourseIdAndSectionIdToExternalActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :external_activities, :course_id, :integer
    add_column :external_activities, :section_id, :integer
  end

  def self.down
    remove_column :external_activities, :course_id
    remove_column :external_activities, :section_id
  end
end
