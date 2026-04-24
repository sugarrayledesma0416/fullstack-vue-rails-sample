class RemoveCompletedCountAllFromGrades < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grades, :completed_count_all
  end

  def self.down
    add_column :grades, :completed_count_all, :integer, :default => 0
  end
end
