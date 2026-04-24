describe CacheManager do
  let(:cache_manager) { described_class.new }
  let(:cache_manager_with_prefix) { described_class.new(test_cache_prefix) }
  let(:test_cache_prefix) { 'my_cache_prefix' }
  let(:test_key) { '1234abc' }
  let(:test_value) { 'jsfUI2131da2f' }

  describe '#cache_put' do
    it 'caches a value to the cache' do
      expect(cache_manager.cache_put(test_key, test_value)).to be true
    end

    it 'caches a value to the cache with a prefix' do
      expect(cache_manager_with_prefix.cache_put(test_key, test_value))
        .to be true
    end

    context 'using TTL' do
      before do
        allow(cache_manager.redis_cache).to receive(:expire).and_call_original
      end

      it 'applies a default ttl value to the entry' do
        cache_manager.cache_put(test_key, test_value)
        expect(cache_manager.redis_cache).to have_received(:expire)
          .with(test_key, 900)  # default value
      end

      it 'applies a ttl value specified in params to the entry' do
        cache_manager.cache_put(test_key, test_value, 300)
        expect(cache_manager.redis_cache).to have_received(:expire)
          .with(test_key, 300)
      end

      it 'cannot retrieve a value when the cache key has expired' do
        cache_manager.cache_put(test_key, test_value, 10)

        expect(cache_manager.cache_get(test_key)).to eq(test_value)
        # expire the key
        cache_manager.redis_cache.expire(test_key, 0)
        expect(cache_manager.cache_get(test_key)).to be_nil
      end

      it 'caches a value to the cache with no TTL' do
        pending 'TODO: Allow setting of key with no ttl'
        cache_manager.cache_put(test_key, test_value, nil)

        expect(cache_manager.cache_get(test_key)).to eq(test_value)
        expect(cache_manager.cache_get_ttl(test_key)).to eq(-1)
      end
    end
  end

  describe '#cache get' do
    it 'retrieves a value from the cache' do
      cache_manager.cache_put(test_key, test_value)
      expect(cache_manager.cache_get(test_key)).to eq(test_value)
    end

    it 'retrieves a value from the cache with a prefix' do
      cache_manager_with_prefix.cache_put(test_key, test_value)
      expect(cache_manager_with_prefix.cache_get(test_key)).to eq(test_value)
    end

    it 'can retrieve values using a prefix override' do
      cache_manager_with_prefix.cache_put(test_key, test_value)
      expect(cache_manager_with_prefix.cache_get("#{test_cache_prefix}-#{test_key}", true))
        .to eq(test_value)
    end
  end

  describe '#cache_get_ttl' do
    it 'returns the ttl of a key' do
      Timecop.freeze do
        cache_manager.cache_put(test_key, test_value, 300)
        expect(cache_manager.cache_get_ttl(test_key)).to eq(300)
      end
    end

    it 'can retrieve the ttl with a prefix override' do
      Timecop.freeze do
        cache_manager_with_prefix.cache_put(test_key, test_value, 300)
        expect(cache_manager_with_prefix.cache_get_ttl("#{test_cache_prefix}-#{test_key}", true))
          .to eq(300)
      end
    end
  end

  describe '#cache_expire' do
    it 'resets the ttl of the key' do
      cache_manager.cache_put(test_key, test_value, 10)

      expect(cache_manager.cache_get(test_key)).to eq(test_value)
      cache_manager.cache_expire(test_key)
      expect(cache_manager.cache_get(test_key)).to be_nil
    end

    it 'can reset the ttl with a prefix override' do
      cache_manager_with_prefix.cache_put(test_key, test_value, 10)

      expect(cache_manager_with_prefix.cache_get(test_key)).to eq(test_value)
      cache_manager_with_prefix.cache_expire("#{test_cache_prefix}-#{test_key}", true)
      expect(cache_manager_with_prefix.cache_get(test_key)).to be_nil
    end
  end
end

