class AddInProgressColumnsToAttempt < ActiveRecord::Migration[4.2]
  def self.up
    add_column :attempts, :save_offset_bytes, :integer, default: 0
    add_column :attempts, :save_record_length, :integer, default: 0
  end

  def self.down
    remove_column :attempts, :save_offset_bytes
    remove_column :attempts, :save_record_length
  end
end
