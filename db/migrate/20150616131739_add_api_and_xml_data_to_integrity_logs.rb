class AddApiAndXmlDataToIntegrityLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :attempt_integrity_logs, :api_data, :text
    add_column :attempt_integrity_logs, :xml_data, :text
  end
end
