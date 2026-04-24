class AddLmsTypeToLtiPlatforms < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_platforms, :lms_type, :string
  end
end
