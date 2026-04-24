class CreateHelpRequests < ActiveRecord::Migration[4.2]
  def self.up
    create_table :help_requests do |hr|
      hr.integer  :user_id
      hr.integer  :program_id
      hr.integer  :activity_id
      hr.integer  :section_id
      hr.integer  :cms_activity_id
      hr.integer  :cms_revision_id
      hr.string   :activity_state
      hr.string   :http_referer
      hr.string   :ip_address
      hr.string   :user_agent_string
      hr.string   :browser_name
      hr.string   :browser_version
      hr.string   :operating_system
      hr.string   :flash_version
      hr.string   :request_params

      hr.timestamps
    end
  end

  def self.down
    drop_table :help_requests
  end
end
