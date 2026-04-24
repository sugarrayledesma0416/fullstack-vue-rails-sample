class AlterCoordsKeyAndCategoryIndicesOnGrades < ActiveRecord::Migration[4.2]
  def self.up
    remove_index :grades, :coordinates_key
    remove_index :grades, :category_id
    add_index    :grades, [:coordinates_key, :category_id], :name => 'by_coord_key_and_category', :length => {:coordinates_key => 12}
  end

  def self.down
    remove_index :grades, :name => :by_coord_key_and_category
    add_index :grades, :coordinates_key
    add_index :grades, :category_id
  end
end
