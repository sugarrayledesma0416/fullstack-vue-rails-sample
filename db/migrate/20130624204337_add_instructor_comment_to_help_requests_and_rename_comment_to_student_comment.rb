class AddInstructorCommentToHelpRequestsAndRenameCommentToStudentComment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_requests, :instructor_comment, :text
    rename_column :help_requests, :comment, :student_comment
  end

  def self.down
    rename_column :help_requests, :student_comment, :comment
    remove_column :help_requests, :instructor_comment
  end
end
