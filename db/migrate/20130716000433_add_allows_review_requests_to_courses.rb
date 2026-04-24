class AddAllowsReviewRequestsToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :allows_review_requests, :bool, :default => true
  end

  def self.down
    remove_column :courses, :allows_review_requests
  end
end
