class CreateCourseStandardSets < ActiveRecord::Migration[6.1]
  def change
    create_table :course_standard_sets do |t|
      t.belongs_to :course
      t.belongs_to :standard_set

      t.timestamps
    end
  end
end
