class AddCommentToGradeOffset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grade_offsets, :comment, :string
  end

  def self.down
    remove_column :grade_offsets, :comment
  end
end
