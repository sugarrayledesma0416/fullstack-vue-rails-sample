class AddShowCommentToGradingSets < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grading_sets, :show_comments, :boolean, :default => false
  end

  def self.down
    remove_column :grading_sets, :show_comments
  end
end
