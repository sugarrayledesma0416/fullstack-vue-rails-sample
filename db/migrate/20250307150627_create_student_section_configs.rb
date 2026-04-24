class CreateStudentSectionConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :student_section_configs do |t|
      t.references :user
      t.references :section
      t.string :video_subtitle_languages, default: 'foreign', null: false
      t.string :video_transcript_languages, default: 'none', null: false
      t.boolean :audio_transcript, default: false, null: false

      t.timestamps
    end
  end
end
