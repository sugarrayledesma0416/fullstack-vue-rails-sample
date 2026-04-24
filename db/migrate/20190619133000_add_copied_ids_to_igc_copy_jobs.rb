class AddCopiedIdsToIgcCopyJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :igc_copy_jobs, :copied_ids, :text
  end
end
