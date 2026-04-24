class AddCompletedCountCurrentandCompletedCountAlltoGrades < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grades, :completed_count_current, :integer, :default => 0
    add_column :grades, :completed_count_all, :integer, :default => 0
  end

  def self.down
    remove_column :grades, :completed_count_current
    remove_column :grades, :completed_count_all
  end
end
