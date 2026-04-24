class AddMaestroVersionAndUrlToPrograms < ActiveRecord::Migration[4.2]
  def self.up
    add_column :programs, :maestro_version, :integer, :default => 3
    add_column :programs, :vhlcentral_subdomain, :string
  end

  def self.down
    remove_column :programs, :vhlcentral_subdomain
    remove_column :programs, :maestro_version
  end
end
