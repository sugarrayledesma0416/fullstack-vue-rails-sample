class CreateAudioSampleTargetActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :audio_sample_target_activities do |table|
      table.integer :activity_revision_id
      table.integer :word_count, null: false
      table.integer :completions_desired, null: false
      table.integer :batch_number, null: false

      table.timestamps
    end
  end
end
