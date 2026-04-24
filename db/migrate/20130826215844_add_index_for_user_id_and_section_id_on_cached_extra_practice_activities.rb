class AddIndexForUserIdAndSectionIdOnCachedExtraPracticeActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_index :cached_extra_practice_activities, [:user_id, :section_id], :name => 'by_user_and_section'
  end

  def self.down
    remove_index :cached_extra_practice_activities, 'by_user_and_section'
  end
end
