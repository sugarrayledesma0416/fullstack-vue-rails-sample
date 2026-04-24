class DropLessonPlans < ActiveRecord::Migration[4.2]
  def change
    drop_table :lesson_plans
  end
end
