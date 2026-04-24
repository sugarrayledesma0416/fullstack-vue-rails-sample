class AddAccessLevelComponentsToCourse < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :access_level, :boolean
    add_column :courses, :components, :string
  end

  def self.down
    remove_column :courses, :components
    remove_column :courses, :access_level
  end
end
