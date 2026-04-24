class AddPointsPendingToGrade < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grades, :points_pending, :integer, :default => 0
  end

  def self.down
    remove_column :grades, :points_pending
  end
end
