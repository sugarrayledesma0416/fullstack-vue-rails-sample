class CreateJobStatusTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :job_status do |job_status|
      job_status.string :name
      job_status.timestamp :last_run_at
      job_status.timestamp :last_success_at
    end
  end

  def self.down
    drop_table :job_status
  end
end
