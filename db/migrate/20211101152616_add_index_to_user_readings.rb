class AddIndexToUserReadings < ActiveRecord::Migration[5.2]
  def change
    add_index(
      :user_readings,
      %i[user_id study_plan_concept_recommendation_id],
      name: 'index_user_readings_by_user_and_recommendation'
    )
  end
end
