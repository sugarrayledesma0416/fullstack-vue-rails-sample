class AddPreviousSectionIdToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :previous_section_id, :integer
  end

  def self.down
    remove_column :assignment_filters, :previous_section_id
  end
end
