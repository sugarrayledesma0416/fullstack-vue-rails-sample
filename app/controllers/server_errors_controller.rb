class ServerErrorsController < ApplicationController
  # in application controller:
  # config.exceptions_app = self.routes

  # in config/routes
  # match '/404' => 'server_errors#show'
  # match '/403' => 'server_errors#show'
  # match '/401' => 'server_errors#show'
  # match '/500' => 'server_errors#show'
  # match '/422' => 'server_errors#show'

  # To see it in action, in config/environments/development.rb set:
  # config.consider_all_requests_local = false

  def show
    @disable_chat_on_page = true
    prepend_view_path 'public'
    @hide_header = true
    begin
      respond_to do |format|
        format.html do
          create_server_error_report unless non_reportable_error?
          render_html_error_page
        end
        format.all { render_non_html_error }
      end
    rescue StandardError => e
      # If our error handler fails, tell VHLMonitor and guarantee that a page renders
      VHLMonitor.notify(e)
      render_html_error_page
    end
  end

  private def original_exception
    @original_exception ||= request.env['action_dispatch.exception']
  end

  private def original_exception_message
    original_exception && original_exception.message
  end

  private def original_exception_location
    original_exception && original_exception.backtrace[0]
  end

  private def status_code
    @status_code ||= if original_exception
                       ActionDispatch::ExceptionWrapper.new(
                         request.env, original_exception
                       ).status_code
                     elsif request.path =~ %r{\A/(40\d)\z}
                       Regexp.last_match[1].to_i
                     else
                       500
                     end
  end

  private def render_html_error_page
    layout = current_user ? 'music_v1/default' : 'music_v1/not_logged_in'
    status_to_render = status_code
    render template: template_path, layout:,
           status: status_to_render, formats: [:html]
  end

  private def render_non_html_error
    render plain: original_exception.message, status: status_code
  end

  private def non_reportable_error?
    # Don't report 401, 403, and 404 pages.
    [404, 401, 403].include?(status_code)
  end

  private def template_path
    case status_code
    # use the 403 page for 401 errors
    when 401 then '403'
    when 403, 404 then status_code.to_s
    else # use generic error for 500, 422, and anything we don't recognize
      '500'
    end
  end

  private def create_server_error_report
    form_params = {
      user_id: (current_user && current_user.id),
      error_id: request.env['rollbar.exception_uuid'],
      http_referer: request.env['HTTP_REFERER'],
      ip_address: request.env['REMOTE_ADDR'],
      user_agent_string: request.env['HTTP_USER_AGENT'],
      operating_system: user_agent.platform,
      browser_name: user_agent.browser,
      browser_version: user_agent.version.to_s,
      error_class: original_exception.class.name,
      error_message: original_exception_message,
      error_location: original_exception_location
    }
    @server_error = ServerErrorReportDispatcher.new(form_params)
    @server_error.dispatch
    Notifier.server_error_report(@server_error).deliver_now unless Rails.env.live?
  end

  private def user_agent
    @user_agent ||= UserAgent.parse(request.user_agent)
  end
end
