class CreateAssignmentSets < ActiveRecord::Migration[5.2]
  def change
    create_table :assignment_sets do |t|
      t.date :due_date
      t.references :section

      t.timestamps
      t.index [:section_id, :due_date]
    end
  end
end
