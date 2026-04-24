class AddOriginallyDueAtInToScoreTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :originally_due_at, :datetime
  end

  def self.down
    remove_column :scores, :originally_due_at
  end
end
