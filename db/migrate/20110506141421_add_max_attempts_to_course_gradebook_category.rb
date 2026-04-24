class AddMaxAttemptsToCourseGradebookCategory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :course_gradebook_categories, :max_attempts, :integer
  end

  def self.down
    remove_column :course_gradebook_categories, :max_attempts
  end
end
