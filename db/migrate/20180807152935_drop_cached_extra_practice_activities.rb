class DropCachedExtraPracticeActivities < ActiveRecord::Migration[4.2]
  def change
    drop_table :cached_extra_practice_activities
  end
end
