class AddUnitLabelAndLessonLabelToPrograms < ActiveRecord::Migration[4.2]
  def self.up
    add_column  :programs, :unit_label, :string
    add_column  :programs, :lesson_label, :string
  end

  def self.down
    remove_column :programs, :unit_label
    remove_column :programs, :lesson_label
  end
end
