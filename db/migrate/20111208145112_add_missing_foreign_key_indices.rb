class AddMissingForeignKeyIndices < ActiveRecord::Migration[4.2]
  def self.up
    add_index :site_licenses, :admin_id
    add_index :settings, :user_id
    add_index :categories, [:course_id, :rank], :name => 'by_course_sort_by_rank'
  end

  def self.down
    remove_index :site_licenses, :admin_id
    remove_index :settings, :user_id
    remove_index :categories, :name => :by_course_sort_by_rank
  end
end
