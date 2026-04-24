class RenameResourceNameToTitle < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :resources, :name, :title
  end

  def self.down
    rename_column :resources, :title, :name
  end
end
