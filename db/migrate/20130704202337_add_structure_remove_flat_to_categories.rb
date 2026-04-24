class AddStructureRemoveFlatToCategories < ActiveRecord::Migration[4.2]
  class Category < ActiveRecord::Base
  end

  def self.up
    add_column :categories, :structure, :string, :default => 'by_lesson_and_strand'
    Category.update_all "structure = (CASE flat WHEN 1 THEN 'flat' ELSE 'by_lesson_and_strand' END)"
    remove_column :categories, :flat
  end

  def self.down
    add_column :categories, :flat, :boolean, :default => 0
    Category.update_all "flat = (CASE structure WHEN 'flat' THEN 1 ELSE 0 END)"
    remove_column :categories, :structure
  end
end
