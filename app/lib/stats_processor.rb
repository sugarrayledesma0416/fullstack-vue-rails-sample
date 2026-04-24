module StatsProcessor
  # include this module in a class that needs to log to logstash
  # required keys environment, application, and vhl_component are added
  #   to the payload in this module

  # payload: (required) a Hash containing the data you want to log
  # stats_index: (required) the index you want the data to appear under
  # stats_type: (optional) sets the 'type' payload key
  # error: (optional) a Ruby Error class object
  def dispatch(payload:, stats_index:, stats_type: nil, error: nil)
    stats = payload.merge(common_stats(stats_index, stats_type))

    if error
      stats[:error_class] = error.class.name
      stats[:error_message] = error.message
      stats[:error_location] = error.backtrace[0]

      STATS_PROXY.error(stats)
    else
      STATS_PROXY.info(stats)
    end
    Rails.logger.debug("STATS_DISPATCH: #{stats.inspect}")
  end

  private def common_stats(index, type = nil)
    {}.tap do |hsh|
      hsh['type'] = type if type.present?
      hsh[:vhl_component] = index
      hsh[:application] = :m3
      hsh[:environment] = Rails.env
    end
  end
end
