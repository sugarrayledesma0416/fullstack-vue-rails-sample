class CreateCustomRubrics < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_rubrics do |t|
      t.bigint :activity_id
      t.bigint :source_activity_id
      t.integer :source_rubric_id
      t.bigint :instructor_id
      t.bigint :course_id
      t.boolean :draft, default: true

      t.index :activity_id
      t.index :source_activity_id

      t.timestamps
    end
  end
end
