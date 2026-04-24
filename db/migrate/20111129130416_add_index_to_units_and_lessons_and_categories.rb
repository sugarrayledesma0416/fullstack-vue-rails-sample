class AddIndexToUnitsAndLessonsAndCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_index :units, :rank
    add_index :lessons, :rank
    add_index :categories, :rank
  end

  def self.down
    remove_index :units, :rank
    remove_index :lessons, :rank
    remove_index :categories, :rank
  end
end
