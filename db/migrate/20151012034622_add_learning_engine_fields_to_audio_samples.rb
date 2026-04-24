class AddLearningEngineFieldsToAudioSamples < ActiveRecord::Migration[4.2]
  def change
    add_column :audio_samples, :self_report_correct, :boolean, null: true
    add_column :audio_samples, :item_index, :integer, null: true
  end
end
