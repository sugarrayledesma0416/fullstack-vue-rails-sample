class AddActivityTypeToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :activity_type, :string
  end

  def self.down
    remove_column :assignment_filters, :activity_type
  end
end
