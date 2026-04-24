class RemoveProgramDescNComponentDescFromPackage < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :packages, :program_description
    remove_column :packages, :component_description
  end

  def self.down
    add_column    :packages, :program_description,    :string
    add_column    :packages, :component_description,  :string
  end
end
