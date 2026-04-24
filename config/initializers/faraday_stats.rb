if Rails.configuration.log_faraday_requests
  # This wrapper takes care of deprecation warnings resulting from the zeitwerk loader
  Rails.application.reloader.to_prepare do
    # configure the Faraday module
    Vhl::Stats::Faraday.configure do |config|
      # add required keys for logstash to Faraday module
      config.required_keys = {
        environment: Rails.env,
        vhl_component: 'faraday'
      }.tap do |memo|
        memo[:application] = if Rails::VERSION::MAJOR >= 6
                               Rails.application.class.module_parent_name
                             else
                               Rails.application.class.parent_name
                             end
      end
    end

    if !Rails.env.test?
      # configure uri sanitizers
      # for stats, we want to replace the id's in the uri with
      # a generic value so they can be counted easily.
      Vhl::Stats::Faraday.configure do |config|
        config.uri_sanitizer do |chain|
          chain.add Vhl::Stats::Faraday::VhlApiUriSanitizer
          chain.add Vhl::Stats::Faraday::SubmissionsUriSanitizer
        end
      end

      # set up subscription to log faraday calls
      ActiveSupport::Notifications.subscribe('request.faraday') do |name, start_time, end_time, token, payload|
        stats = Vhl::Stats::Faraday::Stats.new(start_time, end_time, payload)

        Rails.logger.debug("FARADAY: #{stats.logstash_payload.inspect}")
        STATS_PROXY.info(stats.logstash_payload)
      end
    end
  end
end
