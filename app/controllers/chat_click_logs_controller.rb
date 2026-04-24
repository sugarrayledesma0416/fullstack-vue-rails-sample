class ChatClickLogsController < ApplicationController
  # GET /chat_click_logs
  # GET /chat_click_logs.xml
  def log
    params[:chat_click_log].merge!({:ip => request.remote_ip})
    params[:chat_click_log].merge!({:username => current_user.username}) if current_user
    @chat_click_log = ChatClickLog.new(params[:chat_click_log])
    if request.xhr?
      @chat_click_log.save
      head :ok
    else
      head :not_found
    end
  end
end
