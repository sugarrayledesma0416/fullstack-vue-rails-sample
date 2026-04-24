class AddCourseConfigJsonToCourse < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :course_config_json, :text, default: ''
  end
end
