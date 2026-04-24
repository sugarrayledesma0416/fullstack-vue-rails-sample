class CreateSchools < ActiveRecord::Migration[4.2]
  def self.up
    create_table :schools do |t|
      t.string  :name
      t.string  :school_type
      t.integer :school_type_category
      t.string  :city
      t.string  :state
      t.string  :country
      t.string  :alternate_names
      
      t.timestamps
    end

    add_index :schools, :name
  end

  def self.down
    drop_table :schools
  end
end
