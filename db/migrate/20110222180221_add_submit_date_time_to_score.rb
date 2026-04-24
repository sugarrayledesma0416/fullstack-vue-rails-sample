class AddSubmitDateTimeToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :submitted_at, :datetime
  end

  def self.down
    remove_column :scores, :submitted_at
  end
end
