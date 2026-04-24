class CreateResources < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :resources do |r|
      r.string    :name
      r.string    :file_name
      r.integer   :unit_id,   :null => true
      r.integer   :lesson_id, :null => true
      r.string    :file_type, :null => false
      r.string    :source,    :null => false
      r.integer   :program_id 
      
      r.timestamps
    end  
  end

  def self.down
    drop_table  :resources
  end
end
