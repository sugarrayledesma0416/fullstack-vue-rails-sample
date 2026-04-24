module VhlChat
  class AuthCache
    DEFAULT_EXPIRATION = 86400.freeze  # 24 hours
    NO_CACHE_CONFIG_ERROR = 'AuthCache not configured!'.freeze
    attr_reader :cache_error

    def initialize(cache)
      @cache = cache
      @cache_error = nil

      if defined?(STATS_PROXY) && STATS_PROXY.present?
        self.extend(AuthCacheStats)
      end
    end

    def get_auth(key)
      raise_cache_not_ready_error unless cache_ready?

      JSON.parse(@cache.get(key))
    rescue StandardError => e
      # report error and return an empty hash
      # except if the cache returns nil and JSON.parse causes a TypeError
      unless e.is_a?(TypeError)
        VHLMonitor.notify(e)
        @cache_error = e
      end
      {}
    end

    def store_auth(key, data, expire_seconds = DEFAULT_EXPIRATION)
      raise_cache_not_ready_error unless cache_ready?

      @cache.set(key, data.to_json)
      @cache.expire(key, expire_seconds)
    rescue StandardError => e
      VHLMonitor.notify(e)
      @cache_error = e
      false
    end

    def extend_auth(key, seconds)
      raise_cache_not_ready_error unless cache_ready?

      @cache.expire(key, ttl(key) + seconds)
    rescue StandardError => e
      VHLMonitor.notify(e)
      @cache_error = e
      false
    end

    def ttl(key)
      raise_cache_not_ready_error unless cache_ready?
      # returns # of seconds remaining
      #        -2 if the key does not exist.
      #        -1 if the key exists but has no associated expire.
      @cache.ttl(key)
    rescue StandardError => e
      VHLMonitor.notify(e)
      @cache_error = e
      -2 # this seems like an appropriate return value
    end

    def cache_ready?
      defined?(@cache) && @cache.is_a?(Redis)
    end

    private def raise_cache_not_ready_error
      raise StandardError, NO_CACHE_CONFIG_ERROR
    end
  end
end
