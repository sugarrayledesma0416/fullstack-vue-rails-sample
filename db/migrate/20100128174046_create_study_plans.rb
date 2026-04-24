class CreateStudyPlans < ActiveRecord::Migration[4.2]
  def self.up
    create_table :study_plans do |t|
      t.integer :first_unit_id
      t.integer :last_unit_id
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end

  def self.down
    drop_table :study_plans
  end
end
