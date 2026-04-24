class AddDayToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :day, :date
  end

  def self.down
    remove_column :assignment_filters, :day
  end
end
