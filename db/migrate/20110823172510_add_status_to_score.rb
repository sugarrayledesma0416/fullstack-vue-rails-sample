class AddStatusToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :grading_status, :string, :default => 'auto'
  end

  def self.down
    remove_column :scores, :grading_status
  end
end
