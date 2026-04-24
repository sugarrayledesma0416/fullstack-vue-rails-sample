class ChangeSubmittableToGradableInScore < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :scores, :submittable, :gradable
  end

  def self.down
    rename_column :scores, :gradable, :submittable
  end
end
