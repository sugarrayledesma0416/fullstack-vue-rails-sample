class AddTitlePartsToPrograms < ActiveRecord::Migration[6.1]
  def up
    add_column :programs, :title_part_main, :string
    add_column :programs, :title_part_main_language_code, :string, limit: 2
    add_column :programs, :title_part_sub, :string
    add_column :programs, :title_part_sub_language_code, :string, limit: 2
    add_column :programs, :title_part_edition, :string

    safety_assured do
      execute <<-SQL
        update programs
        set title_part_main = title,
            title_part_main_language_code = language_code;
      SQL
    end
  end

  def down
    remove_column :programs, :title_part_main
    remove_column :programs, :title_part_main_language_code
    remove_column :programs, :title_part_sub
    remove_column :programs, :title_part_sub_language_code
    remove_column :programs, :title_part_edition
  end
end
