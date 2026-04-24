class CreateAudioSampleTargets < ActiveRecord::Migration[4.2]
  def change
    create_table :audio_sample_targets do |table|
      table.integer :dictionary_id
      table.string  :word, null: false
      table.string  :audio_file, null: false
      table.integer :samples_desired, null: false, default: 150
      table.string  :batch_name

      table.timestamps
    end
  end
end
