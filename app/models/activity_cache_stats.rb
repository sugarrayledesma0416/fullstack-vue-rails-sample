module ActivityCacheStats

  def activity_get(redis_key, *cdn_args)
    content = super
    @data_pkgr.dispatch(redis_key, @cache_error)
    content
  end

  def cdn_get(args)
    response = nil
    @data_pkgr.time(:cdn) do
      response = super
    end
    response
  end
  protected :cdn_get

  def redis_get(key)
    response = nil
    @data_pkgr.time(:cache) do
      response = super
    end

    @data_pkgr.cache_hit = response.present?

    response
  end
  protected :redis_get

  class DataPackager

    def initialize(logstash_client)
      @logstash_client = logstash_client
      @timing_data = {}
    end

    def dispatch(redis_key, cache_error)
      cache_info = shared_data(redis_key).merge(cache_data)

      if cache_error.present?
        @logstash_client.error(cache_info.merge(
                                error_class: cache_error.class.name,
                                error_message: cache_error.message,
                                error_location: cache_error.backtrace[0]))
      else
        @logstash_client.info(cache_info) if cache_hit?
      end

      if @timing_data[:cdn].present?
        @logstash_client.info(shared_data(redis_key).merge(
                                hit_source: :cdn,
                                hit_response: @timing_data[:cdn]))
      end
    end

    def cache_hit?
      @cache_hit
    end

    def cache_hit=(val)
      @cache_hit = val
    end

    def time(type)
      start_time = Time.now

      yield

      # calculate timing in milliseconds to 3 decimal places
      @timing_data[type] = ((Time.now - start_time) * 1000).round(3)
    end

    def shared_data(redis_key)
      { vhl_component: :activity_cache,
        application: :m3,
        redis_key: redis_key,
        environment: Rails.env }
    end
    private :shared_data

    def cache_data
      {  hit_source: :cache,
       hit_response: @timing_data[:cache]}
    end
    private :cache_data
  end
end
