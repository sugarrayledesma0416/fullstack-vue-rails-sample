class CreateGrades < ActiveRecord::Migration[4.2]
  def self.up
    create_table :grades do |t|
      t.integer :user_id, :null => false
      t.integer :section_id, :null => false
      t.integer :gradebook_category_id, :null => false
      t.string  :coordinates_key
      t.integer :points_earned
      t.integer :points_possible
      t.integer :activity_count, :null => false, :default => 0
      
      t.timestamps
    end    
  end

  def self.down
    drop_table :grades
  end
end
