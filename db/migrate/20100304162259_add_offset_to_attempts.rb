class AddOffsetToAttempts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :attempts, :offset_bytes, :integer
    add_column :attempts, :record_length, :integer
  end

  def self.down
    remove_column :attempts, :offset_bytes
    remove_column :attempts, :record_length
  end
end
