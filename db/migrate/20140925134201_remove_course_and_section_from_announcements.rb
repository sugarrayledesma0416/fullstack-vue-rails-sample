class RemoveCourseAndSectionFromAnnouncements < ActiveRecord::Migration[4.2]
  def up
    remove_index :announcements, :name => :by_course_sort_by_created_at_desc
    remove_index :announcements, :name => :by_section_sort_by_created_at_desc
    remove_column :announcements, :course_id
    remove_column :announcements, :section_id
  end

  def down
    add_column :announcements, :course_id, :integer
    add_column :announcements, :section_id, :integer
  end
end
