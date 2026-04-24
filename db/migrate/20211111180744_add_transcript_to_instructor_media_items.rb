class AddTranscriptToInstructorMediaItems < ActiveRecord::Migration[5.2]
  def change
    add_column :instructor_media_items, :transcript, :text
  end
end
