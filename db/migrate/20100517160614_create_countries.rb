class CreateCountries < ActiveRecord::Migration[4.2]
  def self.up
    create_table :countries do |t|
      t.string    :code, :null => false
      t.string    :name
    end
    rename_column :schools, :country, :country_code
  end

  def self.down
    drop_table :countries
    rename_column :schools, :country_code, :country
  end
end
