class DropRedemptionStatuses < ActiveRecord::Migration[4.2]
  def change
    drop_table :redemption_statuses
  end
end
