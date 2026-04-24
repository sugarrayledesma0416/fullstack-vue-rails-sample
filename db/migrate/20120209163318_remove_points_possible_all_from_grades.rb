class RemovePointsPossibleAllFromGrades < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grades, :points_possible_all
  end

  def self.down
    add_column :grades, :points_possible_all, :integer
  end
end
