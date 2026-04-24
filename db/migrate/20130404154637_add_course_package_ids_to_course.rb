class AddCoursePackageIdsToCourse < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :course_package_ids, :text
  end

  def self.down
    remove_column :courses, :course_package_ids
  end
end
