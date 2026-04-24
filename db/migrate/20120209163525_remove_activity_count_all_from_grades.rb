class RemoveActivityCountAllFromGrades < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grades, :activity_count_all
  end

  def self.down
    add_column :grades, :activity_count_all, :integer, :null => false, :default => 0
  end
end
