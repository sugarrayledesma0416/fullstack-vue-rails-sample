class AddAudioSampleTargetIdToAudioSamples < ActiveRecord::Migration[4.2]
  def change
    add_column :audio_samples, :audio_sample_target_id, :integer
    add_index :audio_samples, :audio_sample_target_id
  end
end
