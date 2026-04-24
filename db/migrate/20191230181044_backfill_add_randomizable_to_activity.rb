class BackfillAddRandomizableToActivity < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    Activity.unscoped.find_in_batches do |records|
      Activity.unscoped.where(id: records.map(&:id)).update_all randomizable: true
    end
  end
end
