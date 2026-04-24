class CreateNotifications < ActiveRecord::Migration[4.2]
  def self.up
    create_table :notifications do |n|
      n.integer       :user_id
      n.integer       :section_id, :null => true
      n.string        :type
      n.boolean       :dismissed, :default => false
      n.string        :data
      
      n.timestamps      
    end
  end

  def self.down
    drop_table        :notifications
  end
end
