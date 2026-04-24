class ServerErrorReportDispatcher

  def initialize(opts)
    @opts = opts.symbolize_keys
    if @opts[:id].blank?  && @opts[:error_id].blank?
      raise ArgumentError, "One of 'id' or 'error_id' is required"
    end
  end

  def dispatch
    Rails.logger.debug("ERROR REPORT: #{payload}")
    STATS_PROXY.info(payload)
  end

  def default_logstash_params
    {
      vhl_component: 'server_error_report',
      environment: Rails.env,
      vhl_id: id
    }.tap do |memo|
      memo[:application] = if Rails::VERSION::MAJOR >= 6
                             Rails.application.class.module_parent_name
                           else
                             Rails.application.class.parent_name
                           end
    end
  end

  def payload
    default_logstash_params.merge(@opts.tap do |h|
      h[:created_at] = created_at if created_at
      h[:updated_at] = updated_at
      h[:error_id] = id
    end)
  end

  def id
    # id is submitted with the error form
    # error_id comes from error report controller
    @opts[:id] || @opts[:error_id]
  end

  private def created_at
    # if id is present, this is an update and created_at should be blank
    @opts[:created_at] ||= Time.now.utc unless @opts[:id].present?
  end

  private def updated_at
    @opts[:updated_at] ||= Time.now.utc
  end

  def user
    @user ||= User.find_by(id: @opts[:user_id])
  end

  def method_missing(method, *args, &block)
    # accessors for opts, used in emailed reports
    if expected_params.include?(method.to_sym)
      @opts[method.to_sym]
    else
      super
    end
  end

  def expected_params
    [:user_id, :error_id, :http_referer, :ip_address, :user_agent_string,
     :operating_system, :browser_name, :browser_version, :user_comment,
     :error_class, :error_message, :error_location]
  end
end
