class CreateSpeechTutorialCompletions < ActiveRecord::Migration[4.2]
  def change
    create_table :speech_tutorial_completions do |table|
      table.integer :activity_id, null: false
      table.integer :user_id
      table.datetime :completed_at
      table.timestamps
    end

    add_index :speech_tutorial_completions, :activity_id
    add_index :speech_tutorial_completions, :user_id
  end
end
