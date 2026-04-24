class RenameLockedToBlockedTobeConsistentWithUa < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :enrollments, :locked, :blocked
  end

  def self.down
    rename_column :enrollments, :blocked, :locked
  end
end
