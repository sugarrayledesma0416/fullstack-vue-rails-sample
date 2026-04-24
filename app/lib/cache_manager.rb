class CacheManager
  attr_accessor :key_prefix, :separator

  def initialize(key_prefix = '', separator = '-')
    self.key_prefix = key_prefix
    self.separator = separator
  end

  def redis_cache
    return @redis_cache if defined? @redis_cache

    config = Maestro.configuration
    host = config.api_redis_host
    port = config.api_redis_port
    password = if config.api_redis_password == ''
                 nil
               else
                 config.api_redis_password
               end
    @redis_cache = Redis.new(host: host, port: port, password: password)
  end

  # unless otherwise specified, TTL is 15 minutes
  def cache_put(key, value, ttl_seconds = 900)
    put(cache_key(key), value, ttl_seconds)
  end

  def cache_get(key, no_prefix = false)
    get(cache_key(key, no_prefix))
  end

  def cache_expire(key, no_prefix = false)
    redis_cache.expire(cache_key(key, no_prefix), 0)
  end

  def cache_get_ttl(key, no_prefix = false)
    redis_cache.ttl(cache_key(key, no_prefix))
  end

  private def put(key, value, ttl)
    redis_cache.set(key.to_s, value.to_s)
    # TTL is seconds
    redis_cache.expire key.to_s, ttl
  end

  private def get(key)
    redis_cache.get(key.to_s)
  end

  private def cache_key(key, no_prefix = false)
    return key if no_prefix

    key_prefix.empty? ? key : [key_prefix, key].join(separator)
  end
end
