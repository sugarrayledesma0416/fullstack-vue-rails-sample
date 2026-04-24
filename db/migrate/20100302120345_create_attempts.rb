class CreateAttempts < ActiveRecord::Migration[4.2]
  def self.up
    create_table :attempts do |t|
      t.integer  :user_id
      t.integer  :section_id
      t.integer  :activity_id
      t.integer  :status_code

      t.timestamps
    end    
  end

  def self.down
    drop_table :attempts
  end
end
