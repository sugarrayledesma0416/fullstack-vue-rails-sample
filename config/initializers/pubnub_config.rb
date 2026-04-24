config_file = Rails.root.join("config/pubnub.yml")
Rails.configuration.pubnub =
  if File.exist?(config_file) && Rails.configuration.init_pubnub
    yaml = ERB.new(File.read(config_file)).result
    (YAML.safe_load(yaml, aliases: true)[Rails.env] || {}).symbolize_keys
  else
    {}
  end

Rails.logger.debug("PNUB: #{Rails.configuration.pubnub}")

if Rails.configuration.pubnub.present?
  # datadog metrics: Auth Cache circuit breaker (CircuitBox gem)
  tags = ['app:m3',
          "env: #{Rails.env}",
          'role:pnub_grants',
          'platform:maestro']

  # the first two events happen only when the state of the circuit changes
  # the third on each successful call and should provide a sustained indication
  #   that the circuit is active
  ActiveSupport::Notifications.subscribe(/circuit_(open|close|success)/) do |name, start, finish, id, payload|
    Rails.logger.debug("BREAKER: #{name} | #{start} | #{finish} | #{payload.inspect}")
    circuit_name = payload[:circuit]
    # circuit_open happens only when the circuit trips
    # once open, the next event for this subscription will be circuit_close
    STATS_PROXY.config.statsd_logger
      .gauge("chat.pubnub.circuit_breaker.#{circuit_name}.status", (name == 'circuit_open' ? 0 : 1), tags: tags)
  end

  # success and failure are grant call events, skipped occurs when the circuit is open
  ActiveSupport::Notifications.subscribe(/circuit_(success|failure|skipped)/) do |name, start, finish, id, payload|
    Rails.logger.debug("BREAKER: #{name} | #{start} | #{finish} | #{payload.inspect}")
    circuit_name = payload[:circuit]
    STATS_PROXY.config.statsd_logger
      .increment("chat.pubnub.circuit_breaker.#{circuit_name}.#{name}.counter", tags: tags)
  end

  # this one should happen when timing events and when there is an error
  # for errors, there are three notification gauges:
  #    error_rate
  #    sucess_count
  #    failure_count
  ActiveSupport::Notifications.subscribe('circuit_gauge') do |name, start, finish, id, payload|
    Rails.logger.debug("BREAKER: #{name} | #{start} | #{finish} | #{payload.inspect}")
    circuit_name = payload[:circuit]
    [:success_count, :failure_count, :error_rate].each do |circuit_metric|
      if payload[circuit_metric].present?
        STATS_PROXY.config.statsd_logger
          .gauge("chat.pubnub.circuit_breaker.#{circuit_name}.#{name}.#{circuit_metric}", payload[circuit_metric], tags: tags)
      end
    end
  end
end
