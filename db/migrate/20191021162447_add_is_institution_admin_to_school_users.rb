class AddIsInstitutionAdminToSchoolUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :school_users, :is_institution_admin, :boolean, default: false
  end
end
