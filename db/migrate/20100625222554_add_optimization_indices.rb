class AddOptimizationIndices < ActiveRecord::Migration[4.2]
  def self.up
    add_index :activities, :toc_location

    add_index :avatars, :profile_id
    add_index :avatars, :parent_id
    
    add_index :countries, :code
    
    add_index :courses, :program_id
    add_index :courses, :school_id
    
    add_index :enrollments, :user_id
    add_index :enrollments, :section_id
    
    add_index :help_entries, :page
    
    add_index :maestro2_passcodes, :passcode
    add_index :maestro2_passcodes, :redeemer_id
    
    add_index :packages_privileges, :package_id
    
    add_index :passcodes, :passcode_batch_id
    
    add_index :profiles, :user_id
    
    add_index :programs, :vhlcentral_subdomain
    
    add_index :redeemed_passcodes, :user_id
    add_index :redeemed_passcodes, :passcode_id
    
    add_index :roles, :name
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id

    add_index :school_users, [:user_id, :school_id]
        
    add_index :schools, :country_code

    add_index :sections, :course_id
    
    add_index :user_privileges, [:user_id, :privilege_id]
    
    add_index :users, :username
    add_index :users, :persistence_token
  end
  

  def self.down
    remove_index :activities, :toc_location
    
    remove_index :avatars, :profile_id
    remove_index :avatars, :parent_id
    
    remove_index :countries, :code
    
    remove_index :courses, :program_id
    remove_index :courses, :school_id
    
    remove_index :enrollments, :user_id
    remove_index :enrollments, :section_id
    
    remove_index :help_entries, :page
    
    remove_index :maestro2_passcodes, :passcode
    remove_index :maestro2_passcodes, :redeemer_id
    
    remove_index :packages_privileges, :package_id
    
    remove_index :passcodes, :passcode_batch_id
    
    remove_index :profiles, :user_id
    
    remove_index :programs, :vhlcentral_subdomain
    
    remove_index :redeemed_passcodes, :user_id
    remove_index :redeemed_passcodes, :passcode_id
    
    remove_index :roles, :name
    remove_index :roles_users, :user_id
    remove_index :roles_users, :role_id
    
    remove_index :school_users, :column => [:user_id, :school_id]

    remove_index :schools, :country_code
    
    remove_index :sections, :course_id
    
    remove_index :user_privileges, :column => [:user_id, :privilege_id]
    
    remove_index :users, :username
    remove_index :users, :persistence_token
  end
end
