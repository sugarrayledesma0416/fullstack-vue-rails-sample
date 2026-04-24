class AddTransferredFromToEnrollments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :enrollments, :transferred_from, :integer, :null => true
  end

  def self.down
    remove_column :enrollments, :transferred_from
  end
end
