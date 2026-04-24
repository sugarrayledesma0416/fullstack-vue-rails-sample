class RenameServerErrorsAirbrakeIdToErrorId < ActiveRecord::Migration[4.2]
  def change
    rename_column :server_error_reports, :airbrake_error_id, :error_id
  end
end
