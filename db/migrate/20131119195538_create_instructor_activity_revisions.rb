class CreateInstructorActivityRevisions < ActiveRecord::Migration[4.2]
  def change
    create_table :instructor_activity_revisions do |t|
      t.references :activity

      t.timestamps
    end
  end
end
