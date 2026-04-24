describe ActivityCache do
  let(:redis_cache) { double('RedisCache') }
  let(:cdn) { double('cdn') }
  let(:activity_cache) { ActivityCache.new(redis_cache, cdn) }
  let(:xml) { '<activity title="valid title"></activity>' }
  let(:cache_key) { 'cms:123' }
  let(:cdn_path) { 'path/to/123.xml' }

  before do
    allow(redis_cache).to receive(:get).and_return(xml)
    allow(redis_cache).to receive(:set).and_return("OK")
    allow(cdn).to receive(:fetch).and_return(xml)
  end

  describe "#activity_get" do

    context "when there is a cache" do
      context "and the cache key is found" do
        it "retrieves from the cache" do
          expect(redis_cache).to receive(:get).with(cache_key).and_return(xml)
          activity_cache.activity_get(cache_key, cdn_path)
        end
      end

      context "and the cache key is not found" do
        before do
          allow(redis_cache).to receive(:get).and_return(nil)
        end

        it "retrieves from the cdn" do
          expect(cdn).to receive(:fetch).with(cdn_path).and_return(xml)
          activity_cache.activity_get(cache_key, cdn_path)
        end

        it "stores the cdn content in the cache" do
          expect(redis_cache).to receive(:set).with(cache_key, xml).and_return(xml)
          activity_cache.activity_get(cache_key, cdn_path)
        end
      end
    end

    context "when there is no cache" do
      before do
        allow(redis_cache).to receive(:get).and_return(nil)
      end

      it "retrieves from the cdn" do
        expect(cdn).to receive(:fetch).with(cdn_path).and_return(xml)
        activity_cache.activity_get(cache_key, cdn_path)
      end
    end
  end

  describe "#activity_get!" do
    it "retrieves data" do
      expect(redis_cache).to receive(:get).with(cache_key).and_return(xml)
      expect(activity_cache.activity_get!(cache_key, cdn_path)).to eq xml
    end

    it "raises an exception on error" do
      allow(redis_cache).to receive(:get).and_raise('Cache connection error')
      expect { activity_cache.activity_get!(cache_key, cdn_path) }.to raise_error('Cache connection error')
    end
  end

  describe "#redis_set" do
    it "returns the value set whether successful or not" do
      allow(redis_cache).to receive(:set).and_return("OK")
      expect(activity_cache.redis_set(cache_key, xml)).to eq xml
      allow(redis_cache).to receive(:set).and_return(nil)
      expect(activity_cache.redis_set(cache_key, xml)).to eq xml
    end

    it "sets cache_error when set fails" do
      allow(redis_cache).to receive(:set).and_return(nil)
      activity_cache.redis_set(cache_key, xml)
      expect(activity_cache.cache_error.message).to eq "Error setting cache key: '#{cache_key}'"
    end

    it "does not set the cache value if the value is empty" do
      expect(redis_cache).to_not receive(:set)
      activity_cache.redis_set(cache_key, '')
      activity_cache.redis_set(cache_key, nil)
    end

  end
end

describe ActivityCacheStats do
  let(:redis_cache) { double('RedisCache') }
  let(:cdn) { double('cdn') }
  let(:xml) { '<activity title="valid title"></activity>' }
  let(:cache_key) { 'cms:123' }
  let(:cdn_path) { 'path/to/123.xml' }

  let(:activity_cache_with_stats) { ActivityCache.new(redis_cache, cdn, logstash_client) }
  let(:logstash_client) { double('LogstashClient', info: true, error: true) }
  let(:data_pkg) { ActivityCacheStats::DataPackager.new(logstash_client) }

  before do
    allow(ActivityCacheStats::DataPackager).to receive(:new).and_return(data_pkg)
    allow(redis_cache).to receive(:get).and_return(xml)
    allow(redis_cache).to receive(:set).and_return("OK")
    allow(cdn).to receive(:fetch).and_return(xml)
    allow(data_pkg).to receive(:dispatch).with(cache_key, nil)
  end

  it "records cache hits and misses" do
    allow(data_pkg).to receive(:time).and_yield

    allow(redis_cache).to receive(:get).and_return(xml)
    expect(data_pkg).to receive(:cache_hit=).with(true)
    activity_cache_with_stats.activity_get(cache_key, cdn_path)

    allow(redis_cache).to receive(:get).and_return(nil)
    expect(data_pkg).to receive(:cache_hit=).with(false)
    activity_cache_with_stats.activity_get(cache_key, cdn_path)
  end

  it "records timing for cache access" do
    allow(redis_cache).to receive(:get).and_return(xml)
    expect(data_pkg).to receive(:time).with(:cache).and_yield
    activity_cache_with_stats.activity_get(cache_key, cdn_path)
  end

  it "records timing for cdn access" do
    allow(redis_cache).to receive(:get).and_return(nil)
    allow(cdn).to receive(:fetch).and_return(xml)
    allow(data_pkg).to receive(:time).with(:cache).and_yield
    expect(data_pkg).to receive(:time).with(:cdn).and_yield
    activity_cache_with_stats.activity_get(cache_key, cdn_path)
  end

  it "records error conditions" do
    allow(data_pkg).to receive(:time).and_yield
    allow(redis_cache).to receive(:get).and_raise(Redis::CannotConnectError)
    allow(cdn).to receive(:fetch).and_return(xml)
    expect(data_pkg).to receive(:dispatch).with(cache_key, anything)
    activity_cache_with_stats.activity_get(cache_key, cdn_path)
  end
end

describe ActivityCacheStats::DataPackager do
  let(:logstash_client) { double('LogstashClient', info: true, error: true) }
  let(:data_pkg) { TestDataPackager.new(logstash_client) }
  let(:cache_key) { 'cms:123' }
  let(:redis_error) { Redis::CannotConnectError.new }

  describe "#dispatch" do
    before do
      allow(redis_error).to receive(:backtrace).and_return(['some_error_line_info'])
    end

    it 'sends an info message on a cache hit' do
      data_pkg.timing_data[:cache] = 1.52
      data_pkg.cache_hit = true
      expect(logstash_client).to receive(:info).with({vhl_component: :activity_cache,
                                                      redis_key: cache_key,
                                                      environment: 'test',
                                                      application: :m3,
                                                      hit_source: :cache,
                                                      hit_response: data_pkg.timing_data[:cache]})
      data_pkg.dispatch(cache_key, nil)
    end

    it 'sends an info message on a cdn hit' do
      data_pkg.timing_data[:cdn] = 253.34
      expect(logstash_client).to receive(:info).with({vhl_component: :activity_cache,
                                                      redis_key: cache_key,
                                                      environment: 'test',
                                                      application: :m3,
                                                      hit_source: :cdn,
                                                      hit_response: data_pkg.timing_data[:cdn]})
      data_pkg.dispatch(cache_key, nil)
    end

    it 'sends an error message on a cache error' do
      data_pkg.timing_data[:cache] = 1.52
      expect(logstash_client).to receive(:error).with({vhl_component: :activity_cache,
                                                       redis_key: cache_key,
                                                       environment: 'test',
                                                       application: :m3,
                                                       hit_source: :cache,
                                                       hit_response: data_pkg.timing_data[:cache],
                                                       error_class: "Redis::CannotConnectError",
                                                       error_message: "Redis::CannotConnectError",
                                                       error_location: "some_error_line_info"})
      data_pkg.dispatch(cache_key, redis_error)
    end

  end

  describe "#time" do
    it "sets timing information in milliseconds" do
      data_pkg.time(:cdn) { sleep 0.25 }
      expect(data_pkg.timing_data[:cdn]).to be_within(5).of(250)
    end
  end

  class TestDataPackager < ActivityCacheStats::DataPackager
    attr_accessor :timing_data
  end
end
