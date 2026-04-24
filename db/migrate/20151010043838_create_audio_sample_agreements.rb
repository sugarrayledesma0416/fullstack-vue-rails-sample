class CreateAudioSampleAgreements < ActiveRecord::Migration[4.2]
  def change
    create_table :audio_sample_agreements do |table|
      table.integer :user_id, null: false
      table.boolean :allows_recording, null: false, default: false
      table.string :context, default: 'project_george'
      table.timestamps
    end

    add_index :audio_sample_agreements, :user_id
  end
end
