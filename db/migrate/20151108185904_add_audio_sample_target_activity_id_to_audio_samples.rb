class AddAudioSampleTargetActivityIdToAudioSamples < ActiveRecord::Migration[4.2]
  def change
    add_column :audio_samples, :audio_sample_target_activity_id, :integer
    add_index :audio_samples, :audio_sample_target_activity_id
  end
end
