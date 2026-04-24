class ChangeScoresUniqueKeyToScorable < ActiveRecord::Migration[4.2]
  def self.up
    remove_index :scores, [:section_id, :user_id, :activity_id]
    add_index :scores, [:section_id, :user_id, :scorable_id, :scorable_type], :unique => true, :name => 'score_uniqueness'
  end

  def self.down
    add_index :scores, [:section_id, :user_id, :activity_id], :unique => true
    remove_index :scores, :name => 'score_uniqueness'
  end
end
