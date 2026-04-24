class AddIndexesToRecordings < ActiveRecord::Migration[4.2]
  def self.up
    add_index :recordings, :uuid
    add_index :recordings, :recording_path
  end

  def self.down
    remove_index :recordings, :uuid
    remove_index :recordings, :recording_path
  end
end
