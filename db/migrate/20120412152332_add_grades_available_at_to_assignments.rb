class AddGradesAvailableAtToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :grades_available_at, :datetime
  end

  def self.down
    remove_column :assignments, :grades_available_at
  end
end
