class ChageDescriptionFromStringToText < ActiveRecord::Migration[4.2]
  def self.up
    change_column :resources, :description, :text
  end

  def self.down
    change_column :resources, :description, :text
  end
end
