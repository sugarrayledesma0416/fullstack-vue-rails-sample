class RemoveLessonColumnFromUnits < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :units, :lesson
  end

  def self.down
    add_column :units, :lesson, :string, :default => 'Lesson'
  end
end
