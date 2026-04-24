class CreateCourses < ActiveRecord::Migration[4.2]
  def self.up
    create_table :courses do |t|
      t.string :name
      t.string :level
      t.integer :program_id
      t.timestamps
    end
  end

  def self.down
    drop_table :courses
  end
end
