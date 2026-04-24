class AddMultimediaSettingsToSections < ActiveRecord::Migration[6.1]
  def change
    add_column :sections, :audio_transcript, :boolean
    add_column :sections, :video_transcript_languages, :string
    add_column :sections, :video_subtitle_languages, :string
  end
end
