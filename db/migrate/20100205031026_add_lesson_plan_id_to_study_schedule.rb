class AddLessonPlanIdToStudySchedule < ActiveRecord::Migration[4.2]
  def self.up
    add_column :study_schedules, :lesson_plan_id, :integer
  end

  def self.down
    remove_column :study_schedules, :lesson_plan_id
  end
end
