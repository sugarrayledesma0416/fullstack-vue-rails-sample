class AddInstructorTeamIdsToSection < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :instructor_team_ids, :string
  end

  def self.down
    remove_column :sections, :instructor_team_ids
  end
end
