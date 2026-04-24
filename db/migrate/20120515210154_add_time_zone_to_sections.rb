class AddTimeZoneToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :time_zone, :string
  end

  def self.down
    remove_column :sections, :time_zone
  end
end
