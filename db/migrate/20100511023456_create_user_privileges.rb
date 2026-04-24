class CreateUserPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    create_table :user_privileges do |t|
      t.integer  :user_id , :null => false
      t.integer  :privilege_id , :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :user_privileges
  end
end
