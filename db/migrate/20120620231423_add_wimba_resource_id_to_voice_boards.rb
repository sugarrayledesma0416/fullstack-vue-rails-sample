class AddWimbaResourceIdToVoiceBoards < ActiveRecord::Migration[4.2]
  def self.up
    add_column :voice_boards, :wimba_resource_id, :string, :null => false
  end

  def self.down
    remove_column :voice_boards, :wimba_resource_id
  end
end
