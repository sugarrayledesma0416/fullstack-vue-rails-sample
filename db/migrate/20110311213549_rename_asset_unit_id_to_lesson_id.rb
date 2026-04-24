class RenameAssetUnitIdToLessonId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :assets, :unit_id, :lesson_id
  end

  def self.down
    rename_column :assets, :lesson_id, :unit_id
  end
end
