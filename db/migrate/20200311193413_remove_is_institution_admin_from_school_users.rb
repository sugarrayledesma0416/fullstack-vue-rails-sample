class RemoveIsInstitutionAdminFromSchoolUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :school_users, :is_institution_admin }
  end
end
