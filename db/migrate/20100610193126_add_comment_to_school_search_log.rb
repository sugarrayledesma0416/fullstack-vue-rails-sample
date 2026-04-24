class AddCommentToSchoolSearchLog < ActiveRecord::Migration[4.2]
  def self.up
    add_column :school_search_logs, :comment, :string
  end

  def self.down
    remove_column :school_search_logs, :comment
  end
end
