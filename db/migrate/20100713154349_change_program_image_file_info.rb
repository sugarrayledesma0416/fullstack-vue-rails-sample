class ChangeProgramImageFileInfo < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :programs, :image_width
    remove_column :programs, :image_height
    rename_column :programs, :image_path, :image_filename
    Program.connection.execute("UPDATE programs SET image_filename = REPLACE(image_filename, '/images/programs/', '');" )
  end

  def self.down
    Program.connection.execute("UPDATE programs SET image_filename = CONCAT('/images/programs/', image_filename);" )
    rename_column :programs, :image_filename, :image_path
    add_column :programs, :image_height, :integer
    add_column :programs, :image_width, :integer
  end
end
