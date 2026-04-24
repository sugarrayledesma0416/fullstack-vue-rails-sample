class RemoveIsInstitutionAdminControlledFromCourses < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :courses, :is_institution_admin_controlled }
  end
end
