class RenameUnitAndLessonTypeToUseType < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :units, :type, :use_type
    rename_column :lessons, :type, :use_type
  end

  def self.down
    rename_column :units, :use_type, :type
    rename_column :lessons, :use_type, :type
  end
end
