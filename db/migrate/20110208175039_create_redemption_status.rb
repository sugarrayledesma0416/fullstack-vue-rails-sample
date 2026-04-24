class CreateRedemptionStatus < ActiveRecord::Migration[4.2]
  def self.up
    create_table :redemption_statuses do |redemption_status|
      redemption_status.integer :user_id
      redemption_status.integer :failed_count, :default => 0
      redemption_status.datetime :last_failed_at
      redemption_status.timestamps
    end
  end

  def self.down
    drop_table :redemption_statuses
  end
end
