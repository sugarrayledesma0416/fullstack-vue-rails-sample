class AddTimeZoneToSchools < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :time_zone, :string
  end

  def self.down
    remove_column :schools, :time_zone
  end
end
