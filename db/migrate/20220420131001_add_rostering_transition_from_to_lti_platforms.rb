class AddRosteringTransitionFromToLtiPlatforms < ActiveRecord::Migration[5.2]
  def up
    add_column :lti_platforms, :rostering_transition_from, :string, null: true
  end

  def down
    remove_column :lti_platforms, :rostering_transition_from
  end
end
