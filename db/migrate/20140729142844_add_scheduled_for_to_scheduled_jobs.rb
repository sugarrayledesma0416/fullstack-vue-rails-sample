class AddScheduledForToScheduledJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :scheduled_jobs, :scheduled_for, :integer
  end
end
