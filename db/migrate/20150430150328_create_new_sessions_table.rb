class CreateNewSessionsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.integer :user_id
      t.string :ip_address
      t.string :user_agent
      t.string :service_ticket
      t.timestamps
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    add_index :sessions, :service_ticket
  end

  def self.down
    remove_index :sessions, :session_id
    remove_index :sessions, :updated_at
    remove_index :sessions, :service_ticket
    drop_table :sessions
  end
end
