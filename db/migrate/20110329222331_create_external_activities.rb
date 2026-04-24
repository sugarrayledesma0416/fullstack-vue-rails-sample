class CreateExternalActivities < ActiveRecord::Migration[4.2]
  def self.up
    create_table :external_activities do |t|
      t.string  :title
      t.integer :toc_location
      t.integer :lesson_id
      t.integer :toc_location_rank
    end
  end

  def self.down
    drop_table :external_activities
  end
end
