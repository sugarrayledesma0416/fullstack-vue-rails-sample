class AddAbbreviationToPrograms < ActiveRecord::Migration[4.2]
  def self.up
    add_column :programs, :prefix_abbreviation, :string
  end

  def self.down
    remove_column :programs, :prefix_abbreviation
  end
end
