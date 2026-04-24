class AddIndexesToGeneralLog < ActiveRecord::Migration[4.2]
  def self.up
    add_index :general_logs, [:data_id, :log_type], :name => 'data_id_log_type_index'
    add_index :general_logs, :created_at
  end

  def self.down
    remove_index :general_logs, 'data_id_log_type_index'
    remove_index :general_logs, :created_at
  end
end
