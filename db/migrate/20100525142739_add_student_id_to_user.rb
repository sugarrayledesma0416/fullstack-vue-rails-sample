class AddStudentIdToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :student_id, :string
  end

  def self.down
    remove_column :users, :student_id
  end
end
