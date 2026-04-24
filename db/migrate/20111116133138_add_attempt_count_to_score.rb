class AddAttemptCountToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :attempt_count, :integer, :default => 0
  end

  def self.down
    remove_column :scores, :attempt_count
  end
end
