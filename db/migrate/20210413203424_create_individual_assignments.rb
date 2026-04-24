class CreateIndividualAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :individual_assignments do |t|
      t.integer :activity_id
      t.integer :section_id
      t.integer :user_id

      t.index :user_id, name: :index_individual_assignments_on_user_id
      t.index(
        %i[section_id activity_id],
        name: :index_individual_assignments_on_section_id_and_activity_id
      )
    end
  end
end
