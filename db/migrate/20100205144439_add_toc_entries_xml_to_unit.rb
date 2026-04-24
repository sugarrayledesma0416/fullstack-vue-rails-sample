class AddTocEntriesXmlToUnit < ActiveRecord::Migration[4.2]
  def self.up
    add_column :units, :toc_entries_xml, :text
  end

  def self.down
    remove_column :units, :toc_entries_xml
  end
end
