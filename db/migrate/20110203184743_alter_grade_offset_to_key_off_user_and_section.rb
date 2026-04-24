class AlterGradeOffsetToKeyOffUserAndSection < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grade_offsets, :grade_id
    remove_column :grade_offsets, :adjusted_grade
    add_column :grade_offsets, :user_id, :integer, :null => false
    add_column :grade_offsets, :section_id, :integer, :null => false
  end

  def self.down
  end
end
