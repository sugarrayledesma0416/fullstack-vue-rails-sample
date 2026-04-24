class ChangeCoursesHelpRequestsDefaults < ActiveRecord::Migration[4.2]
  def self.up
    change_column :courses, :allows_review_requests, :boolean, :default => false
    change_column :courses, :allows_help_requests, :boolean, :default => false
  end

  def self.down
    change_column :courses, :allows_review_requests, :boolean, :default => true
    change_column :courses, :allows_help_requests, :boolean, :default => true
  end
end
