class AddInputModeToStudentSectionConfig < ActiveRecord::Migration[6.1]
  def up
    add_column :student_section_configs, :input_mode, :string, default: 'speech'
  end

  def down
    remove_column :student_section_configs, :input_mode
  end
end
