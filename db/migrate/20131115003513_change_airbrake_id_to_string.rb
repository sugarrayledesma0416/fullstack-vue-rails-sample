class ChangeAirbrakeIdToString < ActiveRecord::Migration[4.2]
  def self.up
    change_column :server_error_reports, :airbrake_error_id, :string
  end

  def self.down
    change_column :server_error_reports, :airbrake_error_id, :integer
  end
end
