class AddUniquenessToAttempt < ActiveRecord::Migration[4.2]
  def self.up
    add_index :attempts, [:user_id, :section_id, :activity_id, :status_code], :unique => true, :name => 'attempt_uniqueness'
  end

  def self.down
    remove_index :attempts, :name => 'attempt_uniqueness'
  end
end
