class AddUnitIdToLessons < ActiveRecord::Migration[4.2]
  def self.up
    add_column :lessons, :unit_id, :integer
  end

  def self.down
    remove_column :lessons, :unit_id
  end
end
