class CreateGradeOffset < ActiveRecord::Migration[4.2]
  def self.up
    create_table :grade_offsets do |t|
      t.integer :grade_id, :null => false
      t.integer :adjusted_grade
      t.integer :last_offset
      t.timestamps
    end
  end

  def self.down
    drop_table :grade_offsets
  end
end
