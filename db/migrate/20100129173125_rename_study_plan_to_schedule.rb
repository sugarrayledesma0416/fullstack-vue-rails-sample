class RenameStudyPlanToSchedule < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :study_plans, :study_schedules
    rename_column :assignments, :study_plan_id, :study_schedule_id
  end

  def self.down
    rename_column :assignments, :study_schedule_id, :study_plan_id
    rename_table :study_schedules, :study_plans
  end
end
