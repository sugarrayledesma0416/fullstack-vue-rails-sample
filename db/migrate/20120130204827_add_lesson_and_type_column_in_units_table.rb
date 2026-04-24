class AddLessonAndTypeColumnInUnitsTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :units, :type, :string, :default => 'Unit'
    add_column :units, :lesson, :string, :default => 'Lesson'
  end

  def self.down
    remove_column :units, :type
    remove_column :units, :lesson
  end
end
