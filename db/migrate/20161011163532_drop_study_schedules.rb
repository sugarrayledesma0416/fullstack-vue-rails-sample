class DropStudySchedules < ActiveRecord::Migration[4.2]
  def change
    drop_table :study_schedules
  end
end
