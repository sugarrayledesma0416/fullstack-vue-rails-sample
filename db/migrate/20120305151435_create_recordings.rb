class CreateRecordings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :recordings do |r|
      r.string    :recording_path
      r.integer   :user_id
      
      r.timestamps
    end
  end

  def self.down
    drop_table  :recordings
  end
end
