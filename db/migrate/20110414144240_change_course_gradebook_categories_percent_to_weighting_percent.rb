class ChangeCourseGradebookCategoriesPercentToWeightingPercent < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :course_gradebook_categories, :percent, :weighting_percent
    ActiveRecord::Base.connection.execute('UPDATE course_gradebook_categories SET weighting_percent = weighting_percent * 100')
  end

  def self.down
    ActiveRecord::Base.connection.execute('UPDATE course_gradebook_categories SET weighting_percent = weighting_percent / 100')
    rename_column :course_gradebook_categories, :weighting_percent, :percent
  end
end
