class CreateCachedExtraPracticeActivities < ActiveRecord::Migration[4.2]
  def self.up
    create_table :cached_extra_practice_activities do |t|
      t.integer :user_id
      t.integer :section_id
      t.integer :activity_id

      t.timestamps
    end
  end

  def self.down
    drop_table :cached_extra_practice_activities 
  end
end
