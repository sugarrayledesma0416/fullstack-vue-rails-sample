class CreateEnrollments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :enrollments do |t|
      t.integer  :user_id
      t.integer  :section_id
      t.integer  :added_by_id

      t.timestamps

      t.integer  :dropped_by_id
      t.datetime :dropped_at      
    end

  end

  def self.down
    drop_table :enrollments
  end
end
