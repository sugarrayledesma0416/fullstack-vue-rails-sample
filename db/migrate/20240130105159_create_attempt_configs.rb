class CreateAttemptConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :attempt_configs do |t|
      t.integer :artifact_sharing_status, default: 0
      t.belongs_to :attempt
      t.timestamps
    end
  end
end
