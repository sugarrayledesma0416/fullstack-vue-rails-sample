class AddSectionTransferredToToEnrollments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :enrollments, :section_transferred_to, :integer
  end

  def self.down
    remove_column :enrollments, :section_transferred_to
  end
end
