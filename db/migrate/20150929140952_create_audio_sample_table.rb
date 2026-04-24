class CreateAudioSampleTable < ActiveRecord::Migration[4.2]
  def up
    create_table :audio_samples do |t|
      t.integer :user_id
      t.string :word
      t.string :s3_path, limit: 1024
      t.timestamps
    end
  end

  def down
    drop_table :audio_samples
  end
end
