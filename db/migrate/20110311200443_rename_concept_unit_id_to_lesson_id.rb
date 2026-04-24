class RenameConceptUnitIdToLessonId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :concepts, :unit_id, :lesson_id
  end

  def self.down
    rename_column :concepts, :lesson_id, :unit_id
  end
end
