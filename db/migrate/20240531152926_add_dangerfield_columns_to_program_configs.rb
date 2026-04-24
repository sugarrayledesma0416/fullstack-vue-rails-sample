class AddDangerfieldColumnsToProgramConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :program_configs, :guid, :string
    add_column :program_configs, :sync_token, :bigint, default: 0
    add_column :program_configs, :request_id, :string
  end
end
