class AddLtiPlatformIdToLtiLaunches < ActiveRecord::Migration[6.1]
  def up
    add_column :lti_launches, :lti_platform_id, :integer
  end

  def down
    remove_column :lti_launches, :lti_platform_id
  end
end
