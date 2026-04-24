class AddTypeColumnToLessons < ActiveRecord::Migration[4.2]
  def self.up
    add_column :lessons, :type, :string, :default => 'Lesson'
  end

  def self.down
    remove_column :lessons, :type
  end
end
