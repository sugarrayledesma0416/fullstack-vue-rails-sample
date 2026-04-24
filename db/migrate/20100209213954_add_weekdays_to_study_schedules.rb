class AddWeekdaysToStudySchedules < ActiveRecord::Migration[4.2]
  def self.up
    add_column :study_schedules, :weekdays, :string
  end

  def self.down
    remove_column :study_schedules, :weekdays
  end
end
