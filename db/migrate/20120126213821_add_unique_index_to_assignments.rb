class AddUniqueIndexToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_index(:assignments, [:study_schedule_id, :assignable_id, :assignable_type], :length => {:assignable_type => 20}, :unique => true, :name => "assignment_uniqueness")
  end

  def self.down
    remove_index(:assignments, :column => [:study_schedule_id, :assignable_id, :assignable_type])
  end
end
