class AddAccountTypeToSchoolProgramAdminUser < ActiveRecord::Migration[5.2]
  def up
    add_column :school_program_admin_users, :account_type, :string
    change_column_default :school_program_admin_users, :account_type, "InstitutionAdmin"
  end

  def down
    remove_column :school_program_admin_users, :account_type
  end
end
