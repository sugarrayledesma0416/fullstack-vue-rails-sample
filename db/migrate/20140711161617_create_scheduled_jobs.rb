class CreateScheduledJobs < ActiveRecord::Migration[4.2]
  def self.up
    create_table :scheduled_jobs do |t|
      t.string :worker_class, :null => false
      t.text :args
      t.boolean :started, :default => false, :null => false
      t.string :jid, :limit => 24
      t.integer   :enqueued_at
      t.timestamp :created_at
      t.timestamp :updated_at
    end
  end

  def self.down
    drop_table :scheduled_jobs
  end
end
