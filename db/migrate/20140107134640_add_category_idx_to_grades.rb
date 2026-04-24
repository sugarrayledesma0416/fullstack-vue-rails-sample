class AddCategoryIdxToGrades < ActiveRecord::Migration[4.2]
  def change
    add_index :grades, :category_id
  end
end
