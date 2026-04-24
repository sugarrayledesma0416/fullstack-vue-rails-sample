module DatadogProcessor
  # include this module in a class that needs to log to DataDog (statsd)
  # required tags env, app, role and paltform are added
  #   to the payload in this module

  # metric: (required) a String defining the data type
  # stats_type: (required) gauge, timer, or counter
  # role: (required) sets the role in the data tags
  # value: required for gauge, not used for counter and timer
  def ddog_dispatch(metric:, stats_type:, role:, value: nil)
    logger = STATS_PROXY.config.statsd_logger

    case stats_type.to_s
    when 'gauge'
      logger.gauge(metric, value, tags: tags(role))
    when 'timer'
      logger.timer(metric, tags: tags(role))
    when 'counter'
      logger.increment(metric, tags: tags(role))
    end

    Rails.logger.debug("DDOG_DISPATCH: #{metric} - #{role} - #{tags(role).join(',')} - #{value}")
  end

  private def tags(role)
    ['app:m3',
     "env: #{Rails.env}",
     "role:#{role}",
     'platform:maestro']
  end
end
