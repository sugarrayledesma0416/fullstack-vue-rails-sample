class CreateGradingSets < ActiveRecord::Migration[4.2]
  def self.up
    create_table :grading_sets do |t|
      t.integer :program_id
      t.integer :user_id
      t.integer :activity_id
      t.text :student_id_list
      
      t.timestamps
    end
  end

  def self.down
    drop_table :grading_sets
  end
end
