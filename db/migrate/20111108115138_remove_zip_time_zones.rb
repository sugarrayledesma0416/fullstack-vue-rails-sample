class RemoveZipTimeZones < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "zip_time_zones"
  end

  def self.down
    create_table "zip_time_zones", :force => true do |t|
      t.string  "zip_code"
      t.string  "zip_type"
      t.string  "city_name"
      t.string  "city_type"
      t.string  "county_name"
      t.string  "county_fips"
      t.string  "state_name"
      t.string  "state_abbr"
      t.string  "state_fips"
      t.string  "msa_code"
      t.string  "area_code"
      t.string  "time_zone"
      t.decimal "utc",         :precision => 3, :scale => 1
      t.string  "dst"
      t.decimal "latitude",    :precision => 9, :scale => 6
      t.decimal "longitude",   :precision => 9, :scale => 6
    end

    add_index "zip_time_zones", ["state_abbr"], :name => "index_zip_time_zones_on_state_abbr"
    add_index "zip_time_zones", ["time_zone"], :name => "index_zip_time_zones_on_time_zone"
    add_index "zip_time_zones", ["zip_code"], :name => "index_zip_time_zones_on_zip_code"
  end
end
