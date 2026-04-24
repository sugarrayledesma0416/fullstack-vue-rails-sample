class AddSubmittableToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :submittable, :boolean, :default => true
  end

  def self.down
    remove_column :scores, :submittable
  end
end
