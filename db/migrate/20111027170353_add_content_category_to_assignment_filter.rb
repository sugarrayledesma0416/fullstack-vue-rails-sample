class AddContentCategoryToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :content_category, :string
  end

  def self.down
    remove_column :assignment_filters, :content_category
  end
end
