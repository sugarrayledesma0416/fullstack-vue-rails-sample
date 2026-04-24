class AddMediaIdToProgram < ActiveRecord::Migration[4.2]
  def self.up
    add_column :programs, :media_item_id, :integer
  end

  def self.down
    remove_column :programs, :media_item_id
  end
end
