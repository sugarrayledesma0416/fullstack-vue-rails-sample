class AddStartEndDatesAndArchiveToCourse < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :start_date, :datetime
    add_column :courses, :end_date, :datetime
    add_column :courses, :is_archived, :boolean , :default => false
  end

  def self.down
    remove_column :courses, :start_date
    remove_column :courses, :end_date
    remove_column :courses, :is_archived
  end
end
