class ServerErrorReportsController < ApplicationController
  protect_from_forgery except: :update

  def update
    # the id param will serve to locate and merge the comment
    # with the original report
    ServerErrorReportDispatcher.new(safe_params_hash).dispatch
  ensure
    @hide_header = true
    prepend_view_path 'public'
    render template: 'error_report_thank_you', layout: 'music_v1/default'
  end

  def safe_params_hash
    params.permit(
      :browser_name,
      :browser_version,
      :created_at,
      :error_class,
      :error_id,
      :error_location,
      :error_message,
      :http_referer,
      :id,
      :ip_address,
      :operating_system,
      :updated_at,
      :user_agent_string,
      :user_comment,
      :user_id
    ).to_h.symbolize_keys
  end
end
