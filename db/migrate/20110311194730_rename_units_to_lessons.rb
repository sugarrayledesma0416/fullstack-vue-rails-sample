class RenameUnitsToLessons < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :units, :lessons
  end

  def self.down
    rename_table :lessons, :units
  end
end
