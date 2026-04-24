module WorkerInstrumentation
  # By default, if logstash is enabled in sidekiq_config.rb, all workers will
  # send data to logstash.info containing these keys:
  #   :duration (milliseconds)
  #   :environment (Rails.env)
  #   :host (the server name)
  #   :start_time (utc timestamp)
  #   :type (worker class name)
  # Error conditions are also captured and dispatched to logstash.error
  #   :error_class
  #   :error_location
  #   :error_message
  # if you need to send more data to logstash, this module adds a data
  # container accessible to the middleware and a method to add to the contatiner.
  # For example, you could add the arguments passed to the worker.
  # Data can be added at any point by adding
  #   logger_data_merge(your_hash_data)
  # to your worker code.

  def logger_data
    @logger_data ||= HashWithIndifferentAccess.new
  end

  private def logger_data_merge(hsh)
    logger_data.merge!(hsh)
  end

  private def tally_errors(message_array)
    # Ruby 2.7 provides a simple solution
    # message_array.tally
    # for now...
    message_array.group_by(&:itself).transform_values(&:count)
  end
end
