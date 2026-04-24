class AddVideoOptionsToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :video_language_options, :string, :default => 'foreign'
    add_column :courses, :allow_video_transcripts, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :courses, :allow_video_transcripts
    remove_column :courses, :video_language_options
  end
end
