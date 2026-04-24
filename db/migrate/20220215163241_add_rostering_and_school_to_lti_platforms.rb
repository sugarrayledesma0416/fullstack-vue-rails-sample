class AddRosteringAndSchoolToLtiPlatforms < ActiveRecord::Migration[5.2]
  def up
    add_column :lti_platforms, :rostering, :boolean, null: true
    change_column_default :lti_platforms, :rostering, false
    add_column :lti_platforms, :school_id, :integer
  end

  def down
    remove_column :lti_platforms, :school_id
    remove_column :lti_platforms, :rostering
  end
end
