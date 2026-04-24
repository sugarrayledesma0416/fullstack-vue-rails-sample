class AddSchoolIdIndexInSchoolUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_index :school_users, :school_id
  end

  def self.down
    remove_index :school_users, :column => :school_id
  end
end
