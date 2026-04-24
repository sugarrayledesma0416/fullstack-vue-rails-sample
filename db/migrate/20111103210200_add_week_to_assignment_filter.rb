class AddWeekToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :week, :string
  end

  def self.down
    remove_column :assignment_filters, :week
  end
end
