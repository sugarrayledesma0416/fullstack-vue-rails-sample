class AddDeepLinkingSettingsLmsUserIdAndDeploymentIdToLtiLaunches < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :lti_launches, :deep_linking_settings, :text
      add_column :lti_launches, :deployment_id, :string
      add_column :lti_launches, :lms_user_id, :string
    end
  end
end
