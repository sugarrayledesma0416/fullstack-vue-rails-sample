class CreateInternalUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :internal_users do |t|
      t.string  :base_username
      t.string  :department
      t.string  :first_name
      t.string  :last_name
      t.integer :student_user_id
      t.integer :instructor_user_id
      t.integer :admin_user_id

      t.timestamps
    end    
  end

  def self.down
    drop_table :internal_users
  end
end
