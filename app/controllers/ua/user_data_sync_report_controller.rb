require 'coluche/user_data_sync_report'

module Ua
  class UserDataSyncReportController < Ua::ActiveResourceController
    def index
      report = Coluche::UserDataSyncReport.new(user_guid: params[:user_guid]).process
      render json: report.to_json,
             status: report.valid? ? :ok : :unprocessable_entity
    end
  end
end
