class AddAllowHelpRequestsToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :allows_help_requests, :boolean, :default => true
  end

  def self.down
    remove_column :courses, :allows_help_requests
  end
end
