class AddIndexesToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_index :scores, :current
    add_index :scores, :pending
    add_index :scores, :assigned
    add_index :scores, :grading_status
  end

  def self.down
    remove_index :scores, :current
    remove_index :scores, :pending
    remove_index :scores, :assigned
    remove_index :scores, :grading_status
  end
end
