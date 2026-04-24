class AddStudyPlanConceptRecommendations < ActiveRecord::Migration[4.2]
  def change
    create_table :study_plan_concept_recommendations do |table|
      table.integer :study_plan_concept_id, null: false
      table.integer :cms_activity_id
      table.string  :recommendation_type
      table.string  :title

      table.timestamps
    end
  end
end
