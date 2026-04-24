class AddAudioTranscriptsToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :allow_audio_transcripts, :boolean, default: false, null: false
  end
end
