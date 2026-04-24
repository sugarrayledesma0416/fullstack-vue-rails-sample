class DropPasscodeBatches < ActiveRecord::Migration[4.2]
  def change
    drop_table :passcode_batches
  end
end
