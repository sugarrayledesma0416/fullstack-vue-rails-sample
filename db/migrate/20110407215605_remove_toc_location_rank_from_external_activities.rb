class RemoveTocLocationRankFromExternalActivities < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :external_activities, :toc_location_rank
  end

  def self.down
    add_column :external_activities, :toc_location_rank, :integer
  end
end
