class AddLanguageCodeToPrograms < ActiveRecord::Migration[4.2]
  def self.up
    add_column :programs, :language_code, :string, limit: 2, null: true
  end

  def self.down
    remove_column :programs, :language_code
  end

end
