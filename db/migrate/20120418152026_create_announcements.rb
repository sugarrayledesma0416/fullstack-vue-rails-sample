class CreateAnnouncements < ActiveRecord::Migration[4.2]
  def self.up
    create_table :announcements do |t|
      t.integer :course_id, :null => false
      t.integer :section_id
      t.integer :author_id
      t.boolean :is_archived, :default => false, :null => false 
      t.string :title, :null => false
      t.text :body, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :announcements
  end
end
