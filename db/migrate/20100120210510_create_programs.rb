class CreatePrograms < ActiveRecord::Migration[4.2]
  def self.up
    create_table :programs do | t |
      t.string  :title
      t.string  :image_path
      t.integer :image_width
      t.integer :image_height
    
      t.timestamps
    end  
  end

  def self.down
    drop_table :programs
  end
end

