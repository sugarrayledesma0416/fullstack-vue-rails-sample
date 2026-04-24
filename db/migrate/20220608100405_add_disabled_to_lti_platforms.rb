class AddDisabledToLtiPlatforms < ActiveRecord::Migration[5.2]
  def up
    add_column :lti_platforms, :disabled, :boolean
    change_column_default :lti_platforms, :disabled, false
  end

  def down
    remove_column :lti_platforms, :disabled
  end
end
