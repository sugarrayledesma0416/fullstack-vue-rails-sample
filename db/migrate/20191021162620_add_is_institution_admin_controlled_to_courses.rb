class AddIsInstitutionAdminControlledToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :is_institution_admin_controlled, :boolean, default: false
  end
end
