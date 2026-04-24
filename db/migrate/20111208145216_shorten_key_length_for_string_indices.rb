class ShortenKeyLengthForStringIndices < ActiveRecord::Migration[4.2]
  def self.up
    remove_index :roles, :name
    add_index :roles, :name, :length => 20
    
    remove_index :sessions, :session_id
    add_index :sessions, :session_id, :length => 32
    
    remove_index :help_entries, :page
    add_index :help_entries, :page, :length => 32
    
    remove_index :scores, :name => :index_scores_on_user_id_and_scorable_id_and_scorable_type
    add_index :scores, [:user_id, :scorable_id, :scorable_type], :name => 'by_user_and_scorable', :length => {:scorable_type => 16}
  end

  def self.down
    remove_index :roles, :name
    add_index :roles, :name
    
    remove_index :sessions, :session_id
    add_index :sessions, :session_id
    
    remove_index :help_entries, :page
    add_index :help_entries, :page
    
    remove_index :scores, :name => :by_user_and_scorable
    add_index :scores, [:user_id, :scorable_id, :scorable_type]
  end
end
