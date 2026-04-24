class ChangeVideoSettingColumnsInCourses < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :courses, :video_language_options, :video_subtitle_languages
    rename_column :courses, :allow_video_transcripts, :video_transcript_languages
    change_column :courses, :video_transcript_languages, :string, :default => 'none', :null => false
  end

  def self.down
    change_column :courses, :video_transcript_languages, :boolean, :default => false, :null => false
    rename_column :courses, :video_transcript_languages, :allow_video_transcripts
    rename_column :courses, :video_subtitle_languages, :video_language_options
  end
end
