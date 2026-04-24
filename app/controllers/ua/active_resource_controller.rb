class Ua::ActiveResourceController < ApplicationController
  include HttpBasicAuthHelper

  before_action :http_basic_authenticate
  skip_before_action :verify_authenticity_token
  around_action :rescue_and_report_errors

  private

  def rescue_and_report_errors
    begin
      yield
    rescue Exception => e
      Rails.logger.error(e)
      VHLMonitor.notify(e)

      interesting_lines = e.backtrace.reject{|backtrace_line| backtrace_line =~ /\/gems\// }.join("\n")
      render :json => {:status => :failure, :message => e.message, :backtrace => interesting_lines}, :status => 503
    end
  end
end
