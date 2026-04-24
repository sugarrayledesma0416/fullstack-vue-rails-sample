class CreateUnits < ActiveRecord::Migration[4.2]
  def self.up
    create_table :units do |table|
      table.string :name
      table.integer :rank
      table.integer :program_id
      table.string :label      

      table.timestamps
    end
  end

  def self.down
    drop_table :units
  end
end
