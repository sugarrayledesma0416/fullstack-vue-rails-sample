class AddContentTypeToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :content_type, :string
  end

  def self.down
    remove_column :assignment_filters, :content_type
  end
end
