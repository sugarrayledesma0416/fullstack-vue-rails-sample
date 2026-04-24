class RemoveLanguageFromTours < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :tours, :language
  end

  def self.down
  end
end
