class CreateStudentSpotcheckCounts < ActiveRecord::Migration[4.2]
  def self.up
    create_table :student_spotcheck_counts do |t|
      t.integer :user_id, :null => false
      t.integer :section_id, :null => false
      t.integer :count
    end
  end

  def self.down
    drop_table :student_spotcheck_counts
  end
end
