class AddConfigurationXmlToReports < ActiveRecord::Migration[4.2]
  def self.up
    add_column :reports, :configuration_xml, :text
  end

  def self.down
    remove_column :reports, :configuration_xml
  end
end
