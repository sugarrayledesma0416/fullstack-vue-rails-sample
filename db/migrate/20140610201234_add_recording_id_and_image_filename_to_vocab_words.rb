class AddRecordingIdAndImageFilenameToVocabWords < ActiveRecord::Migration[4.2]
  def change
    add_column :vocab_words, :recording_id, :integer
    add_column :vocab_words, :image_filename, :string
  end
end
