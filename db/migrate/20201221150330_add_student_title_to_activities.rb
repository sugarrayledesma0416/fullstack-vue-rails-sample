class AddStudentTitleToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :student_title, :string, default: nil
  end
end
