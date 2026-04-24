class AddStatusColumnToSchoolSearchLog < ActiveRecord::Migration[4.2]
  def self.up
    add_column :school_search_logs, :status, :integer, :default => 1
  end

  def self.down
    remove_column :school_search_logs, :status
  end
end
