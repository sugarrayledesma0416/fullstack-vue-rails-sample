class AddReadByStudentToHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_requests, :read_by_student, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :help_requests, :read_by_student
  end
end
