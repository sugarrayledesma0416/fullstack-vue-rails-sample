class MakeMediaSettingsNullable < ActiveRecord::Migration[6.1]
  def change
    change_column_null :student_section_configs, :video_subtitle_languages, true
    change_column_null :student_section_configs, :video_transcript_languages, true
    change_column_null :student_section_configs, :audio_transcript, true
  end
end
