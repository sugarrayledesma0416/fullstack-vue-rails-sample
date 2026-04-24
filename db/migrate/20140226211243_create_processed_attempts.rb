class CreateProcessedAttempts < ActiveRecord::Migration[4.2]
  def self.up
    create_table :processed_attempts do |t|
      t.integer :attempt_id
      t.timestamps
    end
  end

  def self.down
    drop_table :processed_attempts
  end
end
