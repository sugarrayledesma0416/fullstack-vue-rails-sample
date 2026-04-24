class RemoveStructureFromCategory < ActiveRecord::Migration[4.2]
  def up
    remove_column :categories, :structure
  end

  def down
    add_column :categories, :structure, :string, default: 'by_lesson_and_strand'
  end
end
