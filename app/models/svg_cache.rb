class SvgCache
  DEFAULT_TTL = 1.week.to_i.freeze
  attr_reader :cache_error

  def initialize(redis_cache, cdn)
    @redis_cache = redis_cache
    @cdn = cdn
  end

  def svg_get(redis_key, *cdn_args)
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

  def svg_get!(redis_key, *cdn_args)
    response = svg_get(redis_key, cdn_args)
    raise @cache_error if @cache_error
    response
  end

  private def cdn_get(args)
    @cdn.fetch(args)
  end

  # returns stored value if successful, nil if the key doesn't exist
  private def redis_get(key)
    @redis_cache.get(key)
  end

  def redis_set(key, string_value, ttl = DEFAULT_TTL)
    return string_value unless string_value.present?
    # set() returns "OK" or nil
    # TTL set for 1 week
    unless @redis_cache.set(key, string_value, ex: ttl)
      @cache_error = StandardError.new("Error setting cache key: '#{key}'")
    end
    string_value
  end
end
