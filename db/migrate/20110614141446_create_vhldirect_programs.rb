class CreateVhldirectPrograms < ActiveRecord::Migration[4.2]
  def self.up
    create_table :vhldirect_programs do |t|
      t.integer :program_id, :null => false
      t.string  :name, :null => false
    end
  end

  def self.down
    drop_table :vhldirect_programs
  end
end
