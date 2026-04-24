class AddShowAssessmentToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :show_assessment, :string
    add_column :assignments, :show_at, :datetime
  end

  def self.down
    remove_column :assignments, :show_assessment
    remove_column :assignments, :show_at
  end
end
