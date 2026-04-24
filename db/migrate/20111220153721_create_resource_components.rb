class CreateResourceComponents < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :resource_components do |r|
      r.integer   :program_id
      r.string    :name
      r.integer   :rank,   :null => false, :default => 1
      r.integer   :parent_id, :null => true
            
      r.timestamps
     end 
  end

  def self.down
    drop_table  :resource_components
  end
end
