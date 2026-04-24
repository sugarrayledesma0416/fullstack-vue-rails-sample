class AddContentSummaryToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :content_summary, :text
  end

  def self.down
    remove_column :activities, :content_summary
  end
end
