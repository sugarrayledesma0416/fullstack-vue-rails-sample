class CreateSchoolUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :school_users do |t|
      t.integer  :school_id
      t.integer  :user_id

      t.timestamps
      t.datetime :removed_at
    end

  end

  def self.down
    drop_table :school_users
  end
end
