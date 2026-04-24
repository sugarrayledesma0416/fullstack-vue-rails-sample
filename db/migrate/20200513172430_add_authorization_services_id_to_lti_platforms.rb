class AddAuthorizationServicesIdToLtiPlatforms < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_platforms, :authorization_services_id, :string
  end
end
