class AddCoversToPrograms < ActiveRecord::Migration[6.1]
  def change
    add_column :programs, :cover_path_small, :string
    add_column :programs, :cover_path_medium, :string
    add_column :programs, :cover_path_demo, :string
  end
end
