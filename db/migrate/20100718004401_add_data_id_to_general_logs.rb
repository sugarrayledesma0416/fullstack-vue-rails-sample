class AddDataIdToGeneralLogs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :general_logs, :data_id, :integer
  end

  def self.down
    remove_column :general_logs, :data_id
  end
end
