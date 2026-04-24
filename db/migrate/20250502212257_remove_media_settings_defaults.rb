class RemoveMediaSettingsDefaults < ActiveRecord::Migration[6.1]
  def change
    change_column_default :student_section_configs, :video_subtitle_languages, from: "foreign", to: nil
    change_column_default :student_section_configs, :video_transcript_languages, from: "none", to: nil
    change_column_default :student_section_configs, :audio_transcript, from: false, to: nil
  end
end
