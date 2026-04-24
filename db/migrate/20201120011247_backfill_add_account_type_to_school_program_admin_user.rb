class BackfillAddAccountTypeToSchoolProgramAdminUser < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    SchoolProgramAdminUser.unscoped.in_batches do |relation|
      relation.update_all account_type: "InstitutionAdmin"
      sleep(0.01)
    end
  end
end
