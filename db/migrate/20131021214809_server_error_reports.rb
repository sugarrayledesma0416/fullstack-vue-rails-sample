class ServerErrorReports < ActiveRecord::Migration[4.2]
  def self.up
    create_table :server_error_reports do |t|
      t.references :user
      t.integer :airbrake_error_id
      t.string :http_referer
      t.string :ip_address
      t.string :user_agent_string
      t.string :browser_name
      t.string :browser_version
      t.string :operating_system
      t.text :user_comment
      t.timestamps
    end
  end

  def self.down
    drop_table :server_error_reports
  end
end
