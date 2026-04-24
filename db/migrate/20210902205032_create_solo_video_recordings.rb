class CreateSoloVideoRecordings < ActiveRecord::Migration[5.2]
  def change
    create_table :solo_video_recordings do |t|
      t.integer :user_id
      t.integer :activity_id
      t.string :recording_path

      t.timestamps
    end
  end
end
