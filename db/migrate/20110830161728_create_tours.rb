class CreateTours < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :tours do |t|
      t.boolean   :instructor, :default => false
      t.string    :url
      t.integer   :program_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table  :tours
  end
end
