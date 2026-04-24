class AddOneRosterIntegrationTypeToSchools < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :one_roster_integration_type, :string
  end
end
