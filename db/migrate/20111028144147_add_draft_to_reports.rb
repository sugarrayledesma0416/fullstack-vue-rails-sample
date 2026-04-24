class AddDraftToReports < ActiveRecord::Migration[4.2]
  def self.up
    add_column :reports, :draft, :boolean, :default => true
  end
  def self.down
    remove_column :reports, :draft
  end
end
