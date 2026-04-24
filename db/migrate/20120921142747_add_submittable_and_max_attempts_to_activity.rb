class AddSubmittableAndMaxAttemptsToActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :submittable, :boolean
    add_column :activities, :max_attempts, :integer
    Activity.unscoped.all.each { |activity| activity.save }
  end

  def self.down
    remove_column :activities, :submittable
    remove_column :activities, :max_attempts
  end
end
