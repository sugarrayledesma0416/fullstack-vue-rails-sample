class ChangeCourseStartAndEndDatesFromDateTimesToDates < ActiveRecord::Migration[4.2]
  def self.up
    change_column :courses, :start_date, :date
    change_column :courses, :end_date,   :date
  end

  def self.down
    change_column :courses, :start_date, :datetime
    change_column :courses, :end_date,   :datetime
  end
end
