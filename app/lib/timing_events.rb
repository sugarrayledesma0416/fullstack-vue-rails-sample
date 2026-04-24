module TimingEvents
  def response_time
    @response_time ||= {}
  end

  # use this method to record timing information (e.g. latency for a foreign call)
  #
  #    response = time_event(:optional_event_label) do
  #      create_session()
  #    end
  #
  # returns: the value of the call you are timing
  # timing value is stored in the hash, response_time
  # if you are timing multiple events in your class, pass a unique symbol
  # to time_event so each event will be recorded.
  # fetch the value by calling response_time[:your_label]
  def time_event(event = :default)
    start_time = Time.now

    response = yield
  ensure
    response_time[event] = ((Time.now - start_time) * 1000).to_i # milliseconds
    response
  end
end
