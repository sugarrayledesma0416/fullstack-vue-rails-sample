class AddInformationColumnToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :additional_section_information, :string
  end

  def self.down
    remove_column :sections, :additional_section_information
  end
end
