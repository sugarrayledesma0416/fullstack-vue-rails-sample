class CreateZipTimeZones < ActiveRecord::Migration[4.2]
  def self.up
    create_table :zip_time_zones do |t|
      t.string  :zip_code
      t.string  :zip_type
      t.string  :city_name
      t.string  :city_type
      t.string  :county_name
      t.string  :county_fips
      t.string  :state_name
      t.string  :state_abbr
      t.string  :state_fips
      t.string  :msa_code
      t.string  :area_code
      t.string  :time_zone
      t.decimal :utc, :precision => 3, :scale => 1
      t.string  :dst
      t.decimal :latitude,  :precision => 9, :scale => 6
      t.decimal :longitude, :precision => 9, :scale => 6
    end
    
    add_index :zip_time_zones, :time_zone
    add_index :zip_time_zones, :zip_code
    add_index :zip_time_zones, :state_abbr
  end

  def self.down
    drop_table :zip_time_zones
  end
end
