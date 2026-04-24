class AddUserReadings < ActiveRecord::Migration[4.2]
  def change
    create_table :user_readings do |table|
      table.integer :user_id, null: false
      table.integer :study_plan_concept_recommendation_id, null: false
      table.boolean :viewed
      table.integer :concept_score

      table.timestamps
    end
  end
end
