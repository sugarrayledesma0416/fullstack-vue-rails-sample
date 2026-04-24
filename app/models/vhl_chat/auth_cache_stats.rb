module VhlChat
  module AuthCacheStats

    def get_auth(redis_key)
      data_pkgr.time_and_send(:get_auth) do
        super
      end
    end

    def store_auth(key, data, expire_seconds = VhlChat::AuthCache::DEFAULT_EXPIRATION)
      data_pkgr.time_and_send(:store_auth, data) do
        super
      end
    end

    def extend_auth(key, seconds)
      data_pkgr.time_and_send(:extend_auth) do
        super
      end
    end

    def data_pkgr
      @data_pkgr ||= AuthCacheStats::DataPackager.new(::STATS_PROXY, self)
    end


    class DataPackager
      attr_reader :logstash_client

      def initialize(logstash_client, cache)
        @logstash_client = logstash_client
        @cache = cache
      end

      def time_and_send(action, data = nil)
        start_time = Time.now

        response = yield

        # calculate timing in milliseconds to 3 decimal places
        duration = ((Time.now - start_time) * 1000).round(3)

        # 'data' will be non-nil for :store_auth only (grant data)
        # 'response' will be a hash for :get_auth (also grant data)
        #            and the redis return value for :extend_auth (usually 'OK')
        log_action(action, data || response, duration)

        response
      end

      def log_action(action, data, duration)
        return unless defined?(@logstash_client)

        data_length, data_rate = measurements(data, duration)

        cache_info = required_keys.merge(type: action,
                                         data: filter_data(data),
                                         latency: { duration: duration },  # milliseconds
                                         data_length: data_length, # bytes
                                         data_rate: data_rate,     # bytes / second
                                         service: 'authcache'
                                        )
        if @cache.cache_error.present?
          @logstash_client.error(cache_info.merge(
                                  error_class: @cache.cache_error.class.name,
                                  error_message: @cache.cache_error.message,
                                  error_location: @cache.cache_error.backtrace[0]))
        else
          @logstash_client.info(cache_info)
        end
      end

      def filter_data(data)
        return unless data.is_a?(Hash)
        # :roster is potentially large, contains course data and
        # is not really useful stats-wise
        # TODO: perhaps summarize this info for inclusion in data hash
        data.except('roster', :roster)
      end

      private def measurements(data, duration)
        data_length = data.to_s.length

        data_rate = if duration > 0
          ((data_length * 1000) / duration).to_i
        else
          0
        end

        [data_length, data_rate]
      end

      private def required_keys
        { vhl_component: 'vhl-chat-server-authcache',
          application: :m3,
          environment: Rails.env }
      end
    end
  end
end
