class CreateScreencastsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :screencasts do |t|
      t.string  :title, :null => false
      t.string  :path,  :null => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :screencasts
  end
end
