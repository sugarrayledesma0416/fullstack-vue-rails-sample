class AddStudyPlanConcepts < ActiveRecord::Migration[4.2]
  def change
    create_table :study_plan_concepts do |table|
      table.integer :activity_id, null: false
      table.integer :program_id, null: false
      table.integer :cms_revision_id, null: false
      table.string  :reference_id
      table.string  :title
      table.integer :threshold

      table.timestamps
    end
  end
end
