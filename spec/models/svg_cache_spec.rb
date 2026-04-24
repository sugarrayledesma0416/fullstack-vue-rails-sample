describe SvgCache do
  let(:redis_cache) { double('RedisCache') }
  let(:cdn) { double('cdn') }
  let(:svg_cache) { SvgCache.new(redis_cache, cdn) }
  let(:svg) do
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"></svg>'
  end

  let(:cache_key) { 'svg:m00123456_r0078910' }
  let(:cdn_path) { 'path/to/123.xml' }

  before do
    allow(redis_cache).to receive(:get).and_return(svg)
    allow(redis_cache).to receive(:set).and_return("OK")
    allow(cdn).to receive(:fetch).and_return(svg)
  end

  describe "#svg_get" do
    context "when there is a cache" do
      context "and the cache key is found" do
        it "retrieves from the cache" do
          expect(redis_cache).to receive(:get).with(cache_key).and_return(svg)
          svg_cache.svg_get(cache_key, cdn_path)
        end
      end

      context "and the cache key is not found" do
        before do
          allow(redis_cache).to receive(:get).and_return(nil)
        end

        it "retrieves from the cdn" do
          expect(cdn).to receive(:fetch).with(cdn_path).and_return(svg)
          svg_cache.svg_get(cache_key, cdn_path)
        end

        it "stores the cdn content in the cache" do
          expect(redis_cache).to receive(:set)
            .with(cache_key, svg, ex: described_class::DEFAULT_TTL).and_return(svg)
          svg_cache.svg_get(cache_key, cdn_path)
        end
      end
    end

    context "when there is no cache" do
      before do
        allow(redis_cache).to receive(:get).and_return(nil)
      end

      it "retrieves from the cdn" do
        expect(cdn).to receive(:fetch).with(cdn_path).and_return(svg)
        svg_cache.svg_get(cache_key, cdn_path)
      end
    end
  end

  describe "#svg_get!" do
    it "retrieves data" do
      expect(redis_cache).to receive(:get).with(cache_key).and_return(svg)
      expect(svg_cache.svg_get!(cache_key, cdn_path)).to eq svg
    end

    it "raises an exception on error" do
      allow(redis_cache).to receive(:get).and_raise('Cache connection error')
      expect { svg_cache.svg_get!(cache_key, cdn_path) }
        .to raise_error('Cache connection error')
    end
  end

  describe "#redis_set" do
    it "returns the value set whether successful or not" do
      allow(redis_cache).to receive(:set).and_return("OK")
      expect(svg_cache.redis_set(cache_key, svg)).to eq svg
      allow(redis_cache).to receive(:set).and_return(nil)
      expect(svg_cache.redis_set(cache_key, svg)).to eq svg
    end

    it "sets cache_error when set fails" do
      allow(redis_cache).to receive(:set).and_return(nil)
      svg_cache.redis_set(cache_key, svg)
      expect(svg_cache.cache_error.message).to eq "Error setting cache key: '#{cache_key}'"
    end

    it "does not set the cache value if the value is empty" do
      expect(redis_cache).to_not receive(:set)
      svg_cache.redis_set(cache_key, '')
      svg_cache.redis_set(cache_key, nil)
    end

  end


end
