class AddClientIdToLtiPlatforms < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_platforms, :client_id, :string
  end
end
