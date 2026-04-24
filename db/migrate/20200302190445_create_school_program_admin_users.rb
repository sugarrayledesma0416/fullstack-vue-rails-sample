class CreateSchoolProgramAdminUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :school_program_admin_users do |t|
      t.integer :school_id
      t.integer :program_id
      t.integer :user_id
      t.string  :guid
      t.bigint  :sync_token, default: 0
      t.string  :request_id
      t.timestamps
    end

    add_index :school_program_admin_users,
      [:school_id, :program_id, :user_id],
      name: 'school_id_program_id_user_id_index', unique: true

    add_index :school_program_admin_users,
      [:program_id, :user_id],
      name: 'program_id_user_id_index'

    add_index :school_program_admin_users,
      [:program_id],
      name: 'program_id_index'
  end
end
