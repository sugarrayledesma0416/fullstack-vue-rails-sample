class AddProgramDescNComponentDescToPackage < ActiveRecord::Migration[4.2]
  def self.up
    add_column    :packages, :program_description,    :string
    add_column    :packages, :component_description,  :string
  end

  def self.down
    remove_column :packages, :program_description
    remove_column :packages, :program_description
  end
end
