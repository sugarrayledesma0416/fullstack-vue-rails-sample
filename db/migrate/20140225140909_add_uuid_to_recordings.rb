class AddUuidToRecordings < ActiveRecord::Migration[4.2]
  def self.up
    add_column :recordings, :uuid, :string
  end

  def self.down
    remove_column :recordings, :uuid
  end
end
