class AddUniqueKeyToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_index :scores, [:section_id, :user_id, :activity_id], :unique => true
  end

  def self.down
    remove_index :scores, [:section_id, :user_id, :activity_id]
  end
end
