class RenameContentCategoryToComponentInAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :assignment_filters, :content_category, :component
  end

  def self.down
    rename_column :assignment_filters, :component, :content_category
  end
end
