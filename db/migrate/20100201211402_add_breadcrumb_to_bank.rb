class AddBreadcrumbToBank < ActiveRecord::Migration[4.2]
  def self.up
    add_column :banks, :breadcrumb_string, :string
  end

  def self.down
    remove_column :banks, :breadcrumb_string
  end
end
