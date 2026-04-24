class AddGradingMehtodToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :grading_method, :string
  end

  def self.down
    remove_column :assignment_filters, :grading_method
  end
end
