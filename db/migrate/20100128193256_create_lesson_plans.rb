class CreateLessonPlans < ActiveRecord::Migration[4.2]
  def self.up
    create_table :lesson_plans do |t|
      t.string :description
      t.integer :program_id
      t.string :filename
      
      t.timestamps
    end       
  end

  def self.down
    drop_table :lesson_plans
  end
end
