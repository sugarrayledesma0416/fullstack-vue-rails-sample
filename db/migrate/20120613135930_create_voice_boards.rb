class CreateVoiceBoards < ActiveRecord::Migration[4.2]
  def self.up
    create_table :voice_boards do |t|
      t.integer  :course_id, :null => false
      t.integer  :section_id
      t.string   :title, :null => false
      t.string   :board_type, :null => false
      t.boolean  :is_public_view, :default => false, :null => false 
      t.boolean  :is_archived, :default => false, :null => false
      
      t.timestamps  
    end
  end

  def self.down
    drop_table :voice_boards
  end
end
