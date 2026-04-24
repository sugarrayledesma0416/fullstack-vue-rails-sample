class AddCategoryToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :category_id, :integer
  end

  def self.down
    remove_column :assignment_filters, :category_id
  end
end
