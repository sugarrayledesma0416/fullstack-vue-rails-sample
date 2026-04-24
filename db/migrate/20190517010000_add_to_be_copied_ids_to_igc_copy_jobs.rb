class AddToBeCopiedIdsToIgcCopyJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :igc_copy_jobs, :to_be_copied_ids, :text
  end
end
