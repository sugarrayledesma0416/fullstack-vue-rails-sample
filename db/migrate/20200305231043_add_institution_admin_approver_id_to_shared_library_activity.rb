class AddInstitutionAdminApproverIdToSharedLibraryActivity < ActiveRecord::Migration[5.2]
  def change
    add_column :shared_library_activities, :institution_admin_approver_id, :integer
  end
end
