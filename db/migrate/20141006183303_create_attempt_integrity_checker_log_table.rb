class CreateAttemptIntegrityCheckerLogTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :attempt_integrity_logs do |t|
      t.integer :attempt_id
      t.text :data
      t.boolean :missing_keys, :default => false
      t.boolean :api_data_issue, :default => false
      t.boolean :xml_data_issue, :default => false
      t.boolean :answer_mismatch, :default => false
      t.boolean :resolved, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :attempt_integrity_logs 
  end
end
