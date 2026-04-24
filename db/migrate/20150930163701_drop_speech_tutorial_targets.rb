class DropSpeechTutorialTargets < ActiveRecord::Migration[4.2]
  def up
    drop_table :speech_tutorial_targets
  end

  def down
    create_table :speech_tutorial_targets do |table|
      table.integer :activity_id, null: false
      table.integer :samples_desired, null: false, default: 150
      table.timestamps
    end

    add_index :speech_tutorial_targets, :activity_id
  end
end
