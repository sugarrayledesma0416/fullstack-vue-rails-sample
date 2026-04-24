class CreateAssessmentItems < ActiveRecord::Migration[6.1]
  def change
    create_table :assessment_items do |t|
      t.string :guid, null: false
      t.integer :assessment_id, null: false
      t.integer :points_possible
      t.timestamps
    end

    add_index :assessment_items, :guid
    add_index :assessment_items, :assessment_id
  end
end
