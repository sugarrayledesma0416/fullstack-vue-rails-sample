class AddLanguagesToProfile < ActiveRecord::Migration[4.2]
  def self.up
    add_column :profiles, :languages, :text
  end

  def self.down
    remove_column :profiles, :languages
  end
end
