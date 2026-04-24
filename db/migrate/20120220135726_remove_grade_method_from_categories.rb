class RemoveGradeMethodFromCategories < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :categories, :grade_method
  end

  def self.down
    add_column :categories, :grade_method, :string, :default => 'points'
  end
end
