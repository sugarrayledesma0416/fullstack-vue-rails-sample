class CreateUnitsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :units do |t|
      t.string :name
      t.string :rank
      t.integer :program_id
      
      t.timestamps
    end    
  end

  def self.down
    drop_table :units
  end
end
