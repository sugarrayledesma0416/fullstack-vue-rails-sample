class RemoveAllowsAssessmentsFromCategories < ActiveRecord::Migration[4.2]
  def up
    remove_column :categories, :allows_assessments
  end

  def down
    add_column :categories, :allows_assessments, :boolean
  end
end
