class CreateSectionInstructors < ActiveRecord::Migration[4.2]
  def self.up
    create_table :section_instructors do |t|
      t.integer :section_id
      t.integer :user_id
      t.boolean :is_archived, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :section_instructors
  end
end
