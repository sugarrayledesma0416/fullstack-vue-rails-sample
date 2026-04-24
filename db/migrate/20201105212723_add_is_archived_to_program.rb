class AddIsArchivedToProgram < ActiveRecord::Migration[5.2]
  def up
    add_column :programs, :is_archived, :boolean
    change_column_default :programs, :is_archived, false
  end

  def down
    remove_column :programs, :is_archived
  end
end
