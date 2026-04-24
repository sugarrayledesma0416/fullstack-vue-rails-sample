class RenameUnitIdByStartUnitAndCreateEndUnit < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :resources, :unit_id, :start_unit_id
    add_column :resources, :end_unit_id, :integer, :null => true
  end

  def self.down
    rename_column :resources, :unit_id, :start_unit_id
    remove_column :resources, :end_unit_id
  end
end
