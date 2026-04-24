class AddFirstUnitIdAndLastUnitIdToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :first_unit_id, :integer
    add_column :courses, :last_unit_id, :integer
  end

  def self.down
    remove_column :courses, :last_unit_id
    remove_column :courses, :first_unit_id
  end
end
