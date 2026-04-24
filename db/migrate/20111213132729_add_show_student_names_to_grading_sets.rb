class AddShowStudentNamesToGradingSets < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grading_sets, :show_student_names, :boolean, :default => true
  end

  def self.down
    remove_column :grading_sets, :show_student_names
  end
end
