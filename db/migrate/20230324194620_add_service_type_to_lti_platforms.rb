class AddServiceTypeToLtiPlatforms < ActiveRecord::Migration[6.1]
  def change
    add_column :lti_platforms, :service_type, :string
  end
end
