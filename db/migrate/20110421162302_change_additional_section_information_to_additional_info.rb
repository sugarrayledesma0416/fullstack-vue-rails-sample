class ChangeAdditionalSectionInformationToAdditionalInfo < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :sections, :additional_section_information, :additional_info
  end

  def self.down
    rename_column :sections, :additional_info, :additional_section_information
  end
end
