class AddScorableToScores < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :scorable_id, :integer
    add_column :scores, :scorable_type, :string
  end

  def self.down
    remove_column :scores, :scorable_id
    remove_column :scores, :scorable_type
  end
end
