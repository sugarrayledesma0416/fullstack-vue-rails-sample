module VhlChat
  describe AuthCache do
    let(:redis) { double(Redis) }
    let(:auth_cache) { described_class.new(redis) }
    let(:test_key) { "test key" }
    let(:test_data) do
      {
        user: {
          uuid: "102",
          name: "Albert"
        },
        roster: {
          groups: [{
            id: "course_2",
            name: "Course 2",
            sections: [{
              id: "section_id",
              name: "Section 1"
            }]
          }]
        },
        authToken: "Albert-authkey",
        provider: "pubnub",
        pubnub: {
          publishKey: "pub-c-6af341a2-b7ae-44aa-82f9-48c0d5a195af",
          subscribeKey: "sub-c-cc082852-1f67-11e7-b284-02ee2ddab7fe"
        }
      }
    end

    before do
      allow(auth_cache).to receive(:cache_ready?).and_return(true)
    end

    describe "#get_auth" do
      it "returns an empty hash when the key is not set" do
        allow(redis).to receive(:get).with(test_key).and_return(nil)
        expect(auth_cache.get_auth(test_key)).to eq({})
      end

      it "returns and empty hash when the cache is not configured" do
        auth_cache_no_redis = described_class.new(nil)
        expect(auth_cache_no_redis.get_auth(test_key)).to eq({})
      end

      it "returns an empty hash and reports to rollbar when a redis error occurs" do
        allow(redis).to receive(:get).and_raise(Redis::TimeoutError)
        expect(VHLMonitor).to receive(:notify).with(Redis::TimeoutError)
        expect(auth_cache.get_auth(test_key)).to eq({})
      end
    end

    describe "#store_auth" do
      before do
        allow(redis).to receive(:set)
        allow(redis).to receive(:expire)
      end

      it "stores the data" do
        expect(redis).to receive(:set)
                     .with(test_key, test_data.to_json)
        auth_cache.store_auth(test_key, test_data)
      end

      it "sets a TTL on the key" do
        Timecop.freeze do
          expect(redis).to receive(:expire).with(test_key, 43200)
          auth_cache.store_auth(test_key, test_data, 43200)
        end
      end

      it "returns false if cache is not defined" do
        auth_cache_no_redis = described_class.new(nil)
        expect(auth_cache_no_redis.store_auth(test_key, test_data)).to be false
      end

      it "returns false and reports to rollbar when a redis error occurs" do
        allow(redis).to receive(:set).and_raise(Redis::TimeoutError)
        expect(VHLMonitor).to receive(:notify).with(Redis::TimeoutError)
        expect(auth_cache.store_auth(test_key, test_data)).to be false
      end
    end

    describe "#extend_auth" do
      before do
        allow(redis).to receive(:expire)
        allow(redis).to receive(:ttl).and_return(30)
      end

      it "extends the ttl" do
        Timecop.freeze do
          allow(redis).to receive(:exists).and_return(true)
          # the method checks the current ttl and adds the passed value to it
          allow(redis).to receive(:ttl).and_return(30)
          expect(redis).to receive(:expire).with(test_key, 60)
          auth_cache.extend_auth(test_key, 30)
        end
      end

      it "returns false if cache is not defined" do
        auth_cache_no_redis = described_class.new(nil)
        expect(auth_cache_no_redis.extend_auth(test_key, 30)).to be false
      end

      it "returns false and reports to rollbar when a redis error occurs" do
        allow(redis).to receive(:expire).and_raise(Redis::TimeoutError)
        expect(VHLMonitor).to receive(:notify).with(Redis::TimeoutError)
        expect(auth_cache.extend_auth(test_key, 30)).to be false
      end
    end

    describe "#ttl" do
      before do
        allow(redis).to receive(:ttl).and_return(120)
      end

      it "returns -2 if cache is not defined" do
        auth_cache_no_redis = described_class.new(nil)
        expect(auth_cache_no_redis.ttl(test_key)).to eq -2
      end

      it "returns -2 and reports to rollbar when a redis error occurs" do
        allow(redis).to receive(:ttl).and_raise(Redis::TimeoutError)
        expect(VHLMonitor).to receive(:notify).with(Redis::TimeoutError)
        expect(auth_cache.ttl(test_key)).to eq -2
      end
    end
  end

  describe AuthCacheStats do
    let(:redis_cache) { double('RedisCache') }
    let(:test_data) do
      {
        user: {
          uuid: "102",
          name: "Albert"
        },
        roster: {
          groups: [{
            id: "course_2",
            name: "Course 2",
            sections: [{
              id: "section_id",
              name: "Section 1"
            }]
          }]
        },
        authToken: "Albert-authkey",
        provider: "pubnub",
        pubnub: {
          publishKey: "pub-c-6af341a2-b7ae-44aa-82f9-48c0d5a195af",
          subscribeKey: "sub-c-cc082852-1f67-11e7-b284-02ee2ddab7fe"
        }
      }
    end

    let(:auth_cache_with_stats) { AuthCache.new(redis_cache) }
    let(:logstash_client) { double('LogstashClient', info: true, error: true) }
    let(:data_pkg) { AuthCacheStats::DataPackager.new(logstash_client, @error_ref) }
    let(:cache_key) { "23-ce9fec8629eaba23bc5e17229c67fd9fac8d1ec644094824501be9c751551dd6@xmpp.dev.chat.vhlcentral.com" }

    before do
      allow(AuthCacheStats::DataPackager).to receive(:new).and_return(data_pkg)
      allow(redis_cache).to receive(:get).and_return(test_data)
      allow(redis_cache).to receive(:set).and_return("OK")
      allow(redis_cache).to receive(:expire)
    end

    it "records timing for each method" do
      expect(data_pkg).to receive(:time_and_send).with(:get_auth).and_yield
      auth_cache_with_stats.get_auth(cache_key)

      expect(data_pkg).to receive(:time_and_send).with(:store_auth, test_data).and_yield
      auth_cache_with_stats.store_auth(cache_key, test_data)

      expect(data_pkg).to receive(:time_and_send).with(:extend_auth).and_yield
      auth_cache_with_stats.extend_auth(cache_key, 3600)
    end

    it "records error conditions" do
      allow(data_pkg).to receive(:time_and_send).and_yield
      allow(redis_cache).to receive(:get).and_raise(Redis::CannotConnectError)
      auth_cache_with_stats.get_auth(cache_key)
    end
  end

  describe AuthCacheStats::DataPackager do
    let(:logstash_client) { double('LogstashClient', info: true, error: true) }
    let(:test_auth_cache) { TestAuthCache.new }
    let(:cache_key) { "23-ce9fec8629eaba23bc5e17229c67fd9fac8d1ec644094824501be9c751551dd6@xmpp.dev.chat.vhlcentral.com" }
    let(:redis_error) { Redis::CannotConnectError.new }
    let(:data) { {user: {uuid: 23, name: "vhl_instructor"}} }

    describe "#time_and_send" do
      before do
        allow(test_auth_cache.data_pkgr).to receive(:logstash_client).and_return(logstash_client)
      end

      it "times an event and logs information" do
        expect(test_auth_cache.data_pkgr).to receive(:log_action)
                                         .with(:my_action, data, anything)
        test_auth_cache.data_pkgr.time_and_send(:my_action, data) do
          sleep(0.05)
        end
      end
    end

    describe "#log_action" do

      it 'sends an info message on an action' do
        expect(test_auth_cache.data_pkgr.logstash_client).to receive(:info)
                               .with(hash_including(vhl_component: 'vhl-chat-server-authcache',
                                                    environment: Rails.env,
                                                    application: :m3,
                                                    type: :get_auth,
                                                    service: 'authcache',
                                                    latency: { duration: anything }))
        test_auth_cache.get_auth(cache_key)
      end

      it 'sends an error message on a cache error' do
        expect(test_auth_cache.data_pkgr.logstash_client).to receive(:error)
                               .with(hash_including(vhl_component: 'vhl-chat-server-authcache',
                                                    environment: Rails.env,
                                                    application: :m3,
                                                    type: :store_auth,
                                                    service: 'authcache',
                                                    error_class: "Redis::CannotConnectError",
                                                    error_message: anything,
                                                    error_location: anything))
        # this method in the test class simulates an error
        test_auth_cache.store_auth(cache_key, data)
      end

    end


    class TestAuthCache < AuthCache
      attr_reader :cache_error

      def initialize
        @cache_error = nil
        self.extend(AuthCacheStats)
      end

      def get_auth(key)
        sleep(0.05)
        {user: {uuid: 23, name: "vhl_instructor"}}
      end

      def store_auth(key, data, expire_seconds = 3600)
        sleep(0.05)
        raise Redis::CannotConnectError.new("Connection timed out.")
      rescue StandardError => e
        @cache_error = e
      end

      def extend_auth(key, seconds)
        sleep(0.05)
      end
    end
  end
end
