class AddPasscodeBatchIdToPasscode < ActiveRecord::Migration[4.2]
  def self.up
    add_column :passcodes, :passcode_batch_id, :integer
  end

  def self.down
    remove_column :passcodes, :passcode_batch_id
  end
end
