class AddParentInstitutionIdToSchools < ActiveRecord::Migration[4.2]
  def change
    add_column :schools, :parent_institution_id, :integer, default: nil
    add_index :schools, :parent_institution_id
  end
end
