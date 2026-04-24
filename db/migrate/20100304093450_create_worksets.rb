class CreateWorksets < ActiveRecord::Migration[4.2]
  def self.up
    create_table :worksets do |t|
      t.integer  :user_id
      t.integer  :section_id
      t.string   :activity_list

      t.timestamps
    end    
  end

  def self.down
    drop_table :worksets
  end
end
