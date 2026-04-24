module VHLMonitor
  def notify(exception, context = {})
    VHLMonitor::LogstashNotifier.notify(exception)
    defined?(Rollbar) && Rollbar.error(exception, context.except(:rack_env))
  end
  module_function :notify

  def error(*args)
    defined?(Rollbar) && Rollbar.error(*args)
  end
  module_function :error

  def info(*args)
    defined?(Rollbar) && Rollbar.info(*args)
  end
  module_function :info

  def warning(*args)
    defined?(Rollbar) && Rollbar.warning(*args)
  end
  module_function :warning

  def notify_or_ignore(exception, context = {})
    VHLMonitor::LogstashNotifier.notify(exception, context)
  end
  module_function :notify_or_ignore
end
