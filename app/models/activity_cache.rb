class ActivityCache
  attr_reader :cache_error, :logstash_client

  def initialize(redis_cache, cdn, logstash_client = nil)
    @redis_cache = redis_cache
    @cdn = cdn
    @logstash_client = logstash_client

    if @logstash_client
      self.extend(ActivityCacheStats)
      @data_pkgr = ActivityCacheStats::DataPackager.new(logstash_client)
    end
  end

  def activity_get(redis_key, *cdn_args)
    @cache_error = nil

    if @redis_cache.present?
      begin
        redis_get(redis_key) || redis_set(redis_key, cdn_get(*cdn_args))
      rescue StandardError => e
        @cache_error = e
        cdn_get(*cdn_args)
      end
    else
      cdn_get(*cdn_args)
    end
  end

  def activity_get!(redis_key, *cdn_args)
    response = activity_get(redis_key, cdn_args)
    raise @cache_error if @cache_error
    response
  end

  def cdn_get(args)
    @cdn.fetch(args)
  end
  private :cdn_get

  # returns stored value if successful, nil if it the key doesn't exist
  def redis_get(key)
    @redis_cache.get(key)
  end
  private :redis_get

  def redis_set(key, string_value)
    return string_value unless string_value.present?
    # set() returns "OK" or nil
    unless @redis_cache.set(key, string_value)
      @cache_error = StandardError.new("Error setting cache key: '#{key}'")
    end
    string_value
  end
end
