class AddDraftToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :draft, :boolean, :default => false
  end
  def self.down
    remove_column :courses, :draft
  end
end
