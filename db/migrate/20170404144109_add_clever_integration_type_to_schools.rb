class AddCleverIntegrationTypeToSchools < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :clever_integration_type, :string
  end

  def self.down
    remove_column :schools, :clever_integration_type
  end
end
