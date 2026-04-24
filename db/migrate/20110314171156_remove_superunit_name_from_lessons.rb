class RemoveSuperunitNameFromLessons < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :lessons, :superunit_name
  end

  def self.down
    add_column :lessons, :superunit_name, :string
  end
end
