class AddTitleToPackages < ActiveRecord::Migration[4.2]
  def self.up
    add_column :packages, :title, :string
  end

  def self.down
    remove_column :packages, :title
  end
end
