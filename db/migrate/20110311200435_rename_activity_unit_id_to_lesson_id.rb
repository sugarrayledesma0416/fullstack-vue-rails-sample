class RenameActivityUnitIdToLessonId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :activities, :unit_id, :lesson_id
  end

  def self.down
    rename_column :activities, :lesson_id, :unit_id
  end
end
